# ============================================================================
# External Secrets Operator IAM Role Outputs
# ============================================================================

output "role_name" {
  description = "Name of the External Secrets Operator IAM role"
  value       = module.external_secrets_operator.role_name
}

output "role_arn" {
  description = "ARN of the External Secrets Operator IAM role"
  value       = module.external_secrets_operator.role_arn
}

output "role_id" {
  description = "ID of the External Secrets Operator IAM role"
  value       = module.external_secrets_operator.role_id
}

output "role_unique_id" {
  description = "Unique ID of the External Secrets Operator IAM role"
  value       = module.external_secrets_operator.role_unique_id
}

output "oidc_provider_urls" {
  description = "Map of cluster names to their OIDC provider URLs"
  value       = module.external_secrets_operator.oidc_provider_urls
}

output "cluster_service_accounts" {
  description = "Map of cluster names to their service account subjects"
  value       = module.external_secrets_operator.cluster_service_accounts
}
