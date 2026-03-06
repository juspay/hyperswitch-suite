# ============================================================================
# IAM Role Outputs
# ============================================================================

output "role_name" {
  description = "Name of the ArgoCD management IAM role"
  value       = aws_iam_role.argocd_management.name
}

output "role_arn" {
  description = "ARN of the ArgoCD management IAM role"
  value       = aws_iam_role.argocd_management.arn
}

output "role_id" {
  description = "ID of the ArgoCD management IAM role"
  value       = aws_iam_role.argocd_management.id
}

output "role_unique_id" {
  description = "Unique ID of the ArgoCD management IAM role"
  value       = aws_iam_role.argocd_management.unique_id
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

# Legacy output for backward compatibility
output "service_accounts" {
  description = "[DEPRECATED] List of service accounts - use cluster_service_accounts instead"
  value = try([
    for sa in var.argocd_service_accounts :
    "system:serviceaccount:${var.argocd_namespace}:${sa}"
  ], [])
}
