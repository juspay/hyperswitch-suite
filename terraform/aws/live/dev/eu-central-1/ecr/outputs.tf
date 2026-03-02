# ============================================================================
# ECR Repository Outputs
# ============================================================================

output "repository_arns" {
  description = "Map of repository names to ARNs"
  value       = module.ecr.repository_arns
}

output "repository_urls" {
  description = "Map of repository names to URLs"
  value       = module.ecr.repository_urls
}

output "registry_ids" {
  description = "Map of repository names to registry IDs"
  value       = module.ecr.registry_ids
}

output "repository_names" {
  description = "Map of repository keys to repository names"
  value       = module.ecr.repository_names
}

output "repository_policies" {
  description = "Map of repository keys to their policies"
  value       = module.ecr.repository_policies
}
