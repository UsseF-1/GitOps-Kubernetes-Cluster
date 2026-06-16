output "ecr_vote_url" {
  description = "ECR repository URL for vote service"
  value       = aws_ecr_repository.vote.repository_url
}

output "ecr_result_url" {
  description = "ECR repository URL for result service"
  value       = aws_ecr_repository.result.repository_url
}

output "ecr_worker_url" {
  description = "ECR repository URL for worker service"
  value       = aws_ecr_repository.worker.repository_url
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "kubeconfig_command" {
  description = "Command to generate kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}
