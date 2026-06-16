terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "voting-app-tfstate-shahd"
    key    = "voting-app/terraform.state"
    region = "us-east-1"
  }
}
provider "aws" {
  region = var.aws_region
}


# AWS configuration & S3 backend for state