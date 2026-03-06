# ============================================================================
# ArgoCD Management Role Outputs
# ============================================================================

output "role_name" {
  description = "Name of the ArgoCD management IAM role"
  value       = module.argocd_management_role.role_name
}

output "role_arn" {
  description = "ARN of the ArgoCD management IAM role"
  value       = module.argocd_management_role.role_arn
}

output "role_id" {
  description = "ID of the ArgoCD management IAM role"
  value       = module.argocd_management_role.role_id
}

output "role_unique_id" {
  description = "Unique ID of the ArgoCD management IAM role"
  value       = module.argocd_management_role.role_unique_id
}

output "oidc_provider_urls" {
  description = "Map of cluster names to their OIDC provider URLs"
  value       = module.argocd_management_role.oidc_provider_urls
}

output "cluster_service_accounts" {
  description = "Map of cluster names to their service account subjects"
  value       = module.argocd_management_role.cluster_service_accounts
}

output "service_accounts" {
  description = "List of service accounts that can assume the role (legacy)"
  value       = module.argocd_management_role.service_accounts
}
