output "repository_urls" {
  value = {
    vote   = aws_ecr_repository.vote.repository_url
    result = aws_ecr_repository.result.repository_url
    worker = aws_ecr_repository.worker.repository_url
  }
}