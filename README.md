# GitOps Kubernetes Cluster

**Graduation Project — Digital Egypt Pioneers Initiative (DEPI)**

An end-to-end DevOps platform that provisions a production-style AWS EKS cluster with Terraform, packages a microservices voting application with Helm, and ships changes automatically through a GitHub Actions CI/CD pipeline — with Prometheus/Grafana monitoring and Ansible-based server bootstrapping built in.

The application deployed is the classic **[Example Voting App](https://github.com/dockersamples/example-voting-app)**: a polyglot, multi-service system used here as a realistic workload to exercise the full GitOps toolchain.

---

## Table of Contents

- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Application Overview](#application-overview)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [1. Provision Infrastructure (Terraform)](#1-provision-infrastructure-terraform)
  - [2. Configure Servers (Ansible)](#2-configure-servers-ansible)
  - [3. Build & Push Images (CI/CD)](#3-build--push-images-cicd)
  - [4. Deploy the Application (Helm)](#4-deploy-the-application-helm)
  - [5. Enable Monitoring](#5-enable-monitoring)
- [CI/CD Pipeline](#cicd-pipeline)
- [Environments](#environments)
- [Cost Management](#cost-management)
- [Cleaning Up](#cleaning-up)
- [Team](#team)
- [License](#license)

---

## Architecture

```
                          ┌───────────────────────────────────────────────────────┐
                          │                     GitHub Repository                  │
                          │   (app code · Dockerfiles · Terraform · Helm · CI/CD)  │
                          └───────────────────────────────┬─────────────────────────┘
                                                           │ push / PR
                                                           ▼
                          ┌───────────────────────────────────────────────────────┐
                          │                GitHub Actions Pipeline                 │
                          │  1. Build vote / result / worker images                │
                          │  2. Scan images with Trivy                             │
                          │  3. Push to Amazon ECR                                 │
                          │  4. helm upgrade --install on EKS                      │
                          └───────────────────────────────┬─────────────────────────┘
                                                           │
                                                           ▼
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                                    AWS (Terraform-managed)                            │
│                                                                                        │
│   VPC (public + private subnets, NAT/IGW)                                            │
│      └── EKS Cluster ── managed Node Group ── EBS CSI addon ── OIDC provider          │
│                                                                                        │
│   ┌─────────────────────────────── Kubernetes (Helm release) ─────────────────────┐   │
│   │                                                                                │   │
│   │   Ingress (NGINX)                                                             │   │
│   │      ├── /        → vote (Python/Flask)  ──► Redis ──► worker (.NET)          │   │
│   │      └── /result  → result (Node.js)     ◄── PostgreSQL (PVC via EBS CSI)     │   │
│   │                                                                                │   │
│   │   HPA (optional) on vote / result / worker                                    │   │
│   │   kube-prometheus-stack (Prometheus + Grafana) in the `monitoring` namespace  │   │
│   └────────────────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

**Request/vote flow:** a user casts a vote in the **vote** UI → the vote is queued in **Redis** → the **worker** service consumes it and writes it to **PostgreSQL** → the **result** UI reads from PostgreSQL and displays live results.

---

## Tech Stack

| Layer | Tools |
|---|---|
| Infrastructure as Code | Terraform (AWS VPC, EKS, IAM, EBS CSI, ECR) |
| Container Orchestration | Kubernetes (Amazon EKS) |
| Packaging | Helm 3 (multi-environment values) |
| CI/CD | GitHub Actions |
| Container Registry | Amazon ECR |
| Security Scanning | Trivy |
| Configuration Management | Ansible |
| Monitoring & Observability | Prometheus, Grafana (`kube-prometheus-stack`) |
| Ingress | NGINX Ingress Controller |
| Application | Python (Flask), Node.js, .NET Core, PostgreSQL, Redis |

---

## Repository Structure

```
GitOps-Kubernetes-Cluster/
├── terraform/              # AWS infrastructure: VPC, EKS, IAM, security groups, EBS CSI
│   └── registry/           # Separate stack for ECR repositories
├── ansible/                # Bootstraps a control/dev host: CLI tools, users, SSH hardening
├── docker/                 # Source + Dockerfile for each microservice
│   ├── vote/                  # Python/Flask voting UI
│   ├── result/                 # Node.js results UI
│   └── worker/                 # .NET Core vote processor
├── k8s/                    # Raw Kubernetes manifests (reference / pre-Helm version)
├── helm-chart/              # Helm chart used for actual deployments
│   ├── templates/          # Deployments, Services, Ingress, HPA, PVC, ConfigMap, Secret
│   ├── values.yaml          # Default values
│   ├── values-dev.yaml      # Dev overrides
│   └── values-prod.yaml     # Production overrides
├── monitoring/              # kube-prometheus-stack install script + values
├── .github/workflows/      # CI/CD pipeline (build, scan, push, deploy) + PR checks
└── README.md
```

---

## Application Overview

| Service | Language / Base Image | Port | Responsibility |
|---|---|---|---|
| `vote` | Python 3.11 (Flask) | 80 | Front-end where users cast a vote |
| `result` | Node.js 18 | 4000 | Front-end that displays live results |
| `worker` | .NET Core 7 (multi-stage build) | — | Background service moving votes from Redis into PostgreSQL |
| `redis` | `redis:alpine` | 6379 | Temporary vote queue |
| `db` | `postgres:15-alpine` | 5432 | Persistent vote storage (backed by an EBS-backed PVC) |

All three application images (`vote`, `result`, `worker`) are built from the Dockerfiles in `docker/` and pushed to their own Amazon ECR repositories; `redis` and `postgres` are pulled directly from Docker Hub.

---

## Getting Started

### Prerequisites

- AWS account + AWS CLI configured (`aws configure`)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) ≥ 1.0
- `kubectl`
- [Helm](https://helm.sh/) 3.x
- An S3 bucket for Terraform remote state (referenced in `terraform/provider.tf`)
- (Optional) Ansible, if bootstrapping a local/EC2 control machine

### 1. Provision Infrastructure (Terraform)

First create the container registries, then the cluster:

```bash
# 1a. Create ECR repositories
cd terraform/registry
terraform init
terraform apply

# 1b. Provision the VPC + EKS cluster + node group + EBS CSI driver
cd ../
terraform init
terraform plan
terraform apply
```

This creates:
- A VPC with public/private subnets across 2 AZs, an Internet Gateway, and NAT Gateways
- An EKS cluster (Kubernetes 1.32) with a managed node group (`t3.small`, autoscaling 2–4 nodes)
- IAM roles/policies for the cluster, nodes, and the EBS CSI driver (via OIDC)
- The AWS EBS CSI addon, required for the PostgreSQL PVC

Point `kubectl` at the new cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name voting-cluster
kubectl get nodes
```

### 2. Configure Servers (Ansible)

If you're bootstrapping a bastion/CI/dev host with the tools needed to operate the cluster:

```bash
cd ansible
ansible-playbook -i inventory.ini site.yml
```

This installs AWS CLI, `kubectl`, and Helm, creates a `devops` user with sudo access, and applies basic SSH hardening (disables root login and password auth).

### 3. Build & Push Images (CI/CD)

Images are built and pushed automatically by GitHub Actions on every push to `dev` (see [CI/CD Pipeline](#cicd-pipeline)). To build manually instead:

```bash
docker build -t vote   -f docker/vote/dockerfile.Dockerfile   docker/vote
docker build -t result -f docker/result/dockerfile.Dockerfile docker/result
docker build -t worker -f docker/worker/dockerfile.Dockerfile docker/worker
```

### 4. Deploy the Application (Helm)

```bash
# Install the NGINX Ingress Controller first if it isn't already on the cluster
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Deploy the voting app
helm install voting-app ./helm-chart \
  --values ./helm-chart/values-dev.yaml \
  --create-namespace
```

Check the full [Helm chart documentation](./helm-chart/README.md) for install options, upgrades, rollbacks, HPA, and environment-specific values.

### 5. Enable Monitoring

```bash
cd monitoring
./install.sh
```

This installs the `kube-prometheus-stack` (Prometheus + Grafana + Alertmanager) into a dedicated `monitoring` namespace. See [`monitoring/README.md`](./monitoring/README.md) for details.

---

## CI/CD Pipeline

Two GitHub Actions workflows drive the delivery process:

| Workflow | Trigger | What it does |
|---|---|---|
| `.github/workflows/main.yml` | Pull request → `main` | Runs PR sanity checks before merge |
| `.github/workflows/deploy.yml` | Push → `dev` | Builds, scans, pushes, and deploys the full stack |

**`deploy.yml` pipeline stages:**

1. **Checkout** the repository
2. **Authenticate** to AWS and log in to Amazon ECR
3. **Build** the `vote`, `result`, and `worker` Docker images, tagged with both the commit SHA and `latest`
4. **Scan** each image with **Trivy** for `CRITICAL` vulnerabilities
5. **Push** all images to their ECR repositories
6. **Update kubeconfig** for the target EKS cluster
7. **Deploy** with `helm upgrade --install`, pinning each service to the new image tag (commit SHA)
8. **Verify** rollout by checking pod status

Required GitHub Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`.

---

## Environments

The Helm chart ships with two ready-made environment overlays:

| Setting | Dev (`values-dev.yaml`) | Prod (`values-prod.yaml`) |
|---|---|---|
| Namespace | `voting-dev` | `voting-prod` |
| Vote replicas | 1 | 3 |
| Result replicas | 1 | 2 |
| Worker replicas | 1 | 2 |
| HPA | disabled | enabled (CPU-based) |
| PostgreSQL PVC size | 2Gi | 20Gi |
| Ingress host | `dev.voting.local` | `voting.example.com` |
| Resource requests/limits | reduced | full |

Switch environments at install/upgrade time with `--values ./helm-chart/values-<env>.yaml`.

---

## Cost Management

This project targets an **apply-when-needed, destroy-when-done** workflow to avoid unnecessary AWS charges during development and grading:

```bash
# Bring the environment up
cd terraform && terraform apply

# ...work, test, demo...

# Tear it down when you're finished for the day
terraform destroy
```

The ECR repositories (`terraform/registry`) are kept in a separate Terraform stack precisely so that built images and their tags survive cluster teardown/rebuild cycles.

---

## Cleaning Up

```bash
# Remove the application
helm uninstall voting-app

# Remove monitoring stack
helm uninstall monitoring -n monitoring

# Destroy the cluster and networking
cd terraform && terraform destroy

# Optionally, remove the ECR repositories too
cd terraform/registry && terraform destroy
```

> The PVC and StorageClass use `reclaimPolicy: Retain`, so the underlying EBS volume for PostgreSQL will persist even after `helm uninstall`. Delete it manually with `kubectl delete pvc` / `kubectl delete storageclass` if it's no longer needed.

---

## Team

Built by a 5-person team as the final graduation project for the **Digital Egypt Pioneers Initiative (DEPI)**, covering infrastructure provisioning, CI/CD, Kubernetes/Helm packaging, configuration management, and monitoring.

---

## License

This project is provided for educational purposes as part of the DEPI training program.
