# Voting App — Helm Chart

A production-ready Helm chart for the DEPI GitOps Kubernetes Voting Application.

---

## Chart Structure

```
helm-chart/
├── Chart.yaml                        # Chart metadata
├── values.yaml                       # Default values
├── values-dev.yaml                   # Dev environment overrides
├── values-prod.yaml                  # Production environment overrides
├── .helmignore
├── templates/
│   ├── _helpers.tpl                  # Reusable template helpers
│   ├── NOTES.txt                     # Post-install instructions
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── storageclass.yaml
│   ├── pvc.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml                      # HPA (optional, per component)
│   ├── deployments/
│   │   ├── vote-deployment.yaml
│   │   ├── result-deployment.yaml
│   │   ├── worker-deployment.yaml
│   │   ├── db-deployment.yaml
│   │   └── redis-deployment.yaml
│   └── services/
│       ├── vote-service.yaml
│       ├── result-service.yaml
│       ├── db-service.yaml
│       └── redis-service.yaml
└── README.md
```

---

## Architecture

| Component | Image | Role |
|-----------|-------|------|
| vote | ECR: voting-app-vote | Frontend voting UI (port 80) |
| result | ECR: voting-app-result | Results display UI (port 4000) |
| worker | ECR: voting-app-worker | Background vote processor |
| db | postgres:15-alpine | PostgreSQL database (port 5432) |
| redis | redis:alpine | In-memory vote queue (port 6379) |

---

## Key Values Reference

| Key | Default | Description |
|-----|---------|-------------|
| `namespace` | `default` | Kubernetes namespace |
| `registry` | `569033310103.dkr.ecr.us-east-1.amazonaws.com` | ECR registry for app images |
| `vote.replicaCount` | `1` | Vote deployment replicas |
| `result.replicaCount` | `1` | Result deployment replicas |
| `worker.replicaCount` | `1` | Worker deployment replicas |
| `vote.image.tag` | `V1.0` | Vote image tag |
| `result.image.tag` | `V1.0` | Result image tag |
| `worker.image.tag` | `V1.0` | Worker image tag |
| `pvc.storage` | `5Gi` | PostgreSQL PVC size |
| `ingress.enabled` | `true` | Enable/disable ingress |
| `ingress.host` | `""` | Ingress hostname (empty = no host rule) |
| `vote.hpa.enabled` | `false` | Enable HPA for vote |
| `result.hpa.enabled` | `false` | Enable HPA for result |
| `worker.hpa.enabled` | `false` | Enable HPA for worker |
| `secret.postgres.password` | `cG9zdGdyZXM=` | Base64 encoded Postgres password |

---

## Installation

### Prerequisites

- Helm 3.x
- `kubectl` configured against your cluster
- AWS EBS CSI driver installed (for StorageClass)
- NGINX Ingress Controller installed

### Install — Default

```bash
helm install voting-app ./helm-chart
```

### Install — Dev Environment

```bash
helm install voting-app ./helm-chart \
  --values ./helm-chart/values-dev.yaml \
  --create-namespace
```

### Install — Production

```bash
helm install voting-app ./helm-chart \
  --values ./helm-chart/values-prod.yaml \
  --create-namespace
```

### Install — Custom Image Tag

```bash
helm install voting-app ./helm-chart \
  --set vote.image.tag=V2.0 \
  --set result.image.tag=V2.0 \
  --set worker.image.tag=V2.0
```

### Install — Custom Password

```bash
# Generate base64 password first
echo -n "mysecretpassword" | base64

helm install voting-app ./helm-chart \
  --set secret.postgres.password=<base64-encoded-value>
```

---

## Upgrade

```bash
# Upgrade with new image tags
helm upgrade voting-app ./helm-chart \
  --set vote.image.tag=V2.0 \
  --set result.image.tag=V2.0 \
  --set worker.image.tag=V2.0

# Upgrade with a values file
helm upgrade voting-app ./helm-chart \
  --values ./helm-chart/values-prod.yaml

# Upgrade and reset values to chart defaults
helm upgrade voting-app ./helm-chart --reset-values
```

---

## Rollback

```bash
# View release history
helm history voting-app

# Rollback to previous revision
helm rollback voting-app

# Rollback to a specific revision
helm rollback voting-app 2
```

---

## Uninstall

```bash
helm uninstall voting-app
```

> **Note:** The PersistentVolumeClaim (`pvc-db`) and StorageClass use `reclaimPolicy: Retain`,
> so EBS data persists after uninstall. Delete manually if no longer needed:
> ```bash
> kubectl delete pvc pvc-db
> kubectl delete storageclass storage-class-db
> ```

---

## Dry Run & Lint

```bash
# Lint the chart
helm lint ./helm-chart

# Dry run to preview rendered manifests
helm install voting-app ./helm-chart --dry-run --debug

# Render templates locally without a cluster
helm template voting-app ./helm-chart
```

---

## Horizontal Pod Autoscaler

HPA is disabled by default. To enable for production:

```bash
helm upgrade voting-app ./helm-chart \
  --values ./helm-chart/values-prod.yaml \
  --set vote.hpa.enabled=true \
  --set result.hpa.enabled=true \
  --set worker.hpa.enabled=true
```

Requires the Kubernetes Metrics Server to be installed in the cluster.

---

## Environment Differences

| Setting | Dev | Prod |
|---------|-----|------|
| namespace | `voting-dev` | `voting-prod` |
| vote replicas | 1 | 3 |
| result replicas | 1 | 2 |
| worker replicas | 1 | 2 |
| HPA | disabled | enabled |
| PVC size | 2Gi | 20Gi |
| Ingress host | `dev.voting.local` | `voting.example.com` |
| Resource limits | reduced | full |


---

## Monitoring Stack

The Helm chart also supports deploying a complete Kubernetes monitoring stack using the **Prometheus Community kube-prometheus-stack**.

The monitoring stack includes:

| Component | Purpose |
|-----------|---------|
| Prometheus | Collects and stores metrics from Kubernetes and application workloads |
| Grafana | Visualizes metrics using customizable dashboards |
| Alertmanager | Manages and routes alerts generated by Prometheus |
| Node Exporter | Collects host-level metrics from Kubernetes nodes |
| kube-state-metrics | Exposes Kubernetes object metrics |

---

## Monitoring Configuration

The monitoring components are configured through `values.yaml` and use persistent AWS EBS volumes for data retention.

### Grafana

| Setting | Value |
|----------|------|
| Enabled | `true` |
| Service Type | `LoadBalancer` |
| Persistent Storage | `10Gi` |
| StorageClass | `storage-class-db` |
| Default Dashboards | Enabled |
| Dashboard Sidecar | Enabled |

Grafana automatically imports several Kubernetes dashboards during installation.

Included dashboards:

| Dashboard | Grafana ID |
|-----------|-----------|
| Node Exporter Full | 1860 |
| Kubernetes Cluster Monitoring | 315 |
| Kubernetes Global Metrics | 15757 |
| Kubernetes Nodes | 15759 |
| Kubernetes Pods | 15760 |
| Kubernetes Deployments | 15761 |

### Prometheus

| Setting | Value |
|----------|------|
| Service Type | `LoadBalancer` |
| Persistent Storage | `20Gi` |
| StorageClass | `storage-class-db` |

Prometheus stores monitoring data on persistent storage, ensuring metrics remain available after pod restarts.

### Alertmanager

| Setting | Value |
|----------|------|
| Persistent Storage | `5Gi` |
| StorageClass | `storage-class-db` |

Alertmanager stores its configuration and silences on persistent storage.

---
