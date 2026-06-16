variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}
variable "project_name" {
  description = "Project Name"
  default     = "voting-app"
}
variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}
variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
variable "cluster_name" {
  description = "EKS cluster name"
  default     = "voting-cluster"
}
variable "node_instance_type" {
  description = "EC2 instance for node group"
  default     = "t3.micro"
}
variable "node_group_size" {
  description = "Node group size"
  default     = 2
}
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  default     = "1.32"
}
# All configurable settings