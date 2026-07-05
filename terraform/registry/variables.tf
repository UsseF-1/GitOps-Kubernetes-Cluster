variable "project_name" {
  description = "Prefix for resources"
  type        = string
  default = "voting-app"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}