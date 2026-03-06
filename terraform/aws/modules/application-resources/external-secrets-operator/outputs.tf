# ============================================================================
# IAM Role Outputs
# ============================================================================

output "role_name" {
  description = "Name of the External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets.name
}

output "role_arn" {
  description = "ARN of the External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets.arn
}

output "role_id" {
  description = "ID of the External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets.id
}

output "role_unique_id" {
  description = "Unique ID of the External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets.unique_id
}

# ============================================================================
# Additional Outputs
# ============================================================================

output "oidc_provider_urls" {
  description = "Map of cluster names to their OIDC provider URLs"
  value = {
    for cluster_name, statement in local.cluster_oidc_statements :
    cluster_name => statement.oidc_url
  }
}

output "cluster_service_accounts" {
  description = "Map of cluster names to their service account subjects"
  value = {
    for cluster_name, statement in local.cluster_oidc_statements :
    cluster_name => statement.subjects
  }
}

output "secrets_manager_policy_json" {
  description = "JSON of the Secrets Manager access policy"
  value       = data.aws_iam_policy_document.secrets_manager_access.json
}
