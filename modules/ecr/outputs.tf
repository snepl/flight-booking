output "repo_urls" {
  description = "Map of repo name -> repository URL"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}
