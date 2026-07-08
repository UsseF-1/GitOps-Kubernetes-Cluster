terraform {
    backend "s3" {
        bucket = "voting-app-s3-ecr"
        key    = "dev/terraform.tfstate"
        region = "us-east-1"
        encrypt        = true
    }
}