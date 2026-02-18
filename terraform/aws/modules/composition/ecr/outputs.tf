# ECR Repository Outputs
output "repository_arns" {
  description = "Map of repository names to ARNs"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.arn }
}

output "repository_urls" {
  description = "Map of repository names to URLs"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.repository_url }
}

output "registry_ids" {
  description = "Map of repository names to registry IDs"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.registry_id }
}

output "repository_names" {
  description = "Map of repository keys to repository names"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.name }
}

output "repository_policies" {
  description = "Map of repository keys to their policies"
  value       = { for k, v in aws_ecr_repository_policy.policies : k => v.policy }
}
