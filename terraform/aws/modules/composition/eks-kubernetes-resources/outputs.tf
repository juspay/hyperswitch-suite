# =============================================================================
# EKS Kubernetes Resources Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# RBAC Outputs
# -----------------------------------------------------------------------------
output "rbac_roles_created" {
  description = "List of RBAC roles created"
  value = compact([
    var.create_default_rbac_roles ? "cluster-developer" : null,
    var.create_default_rbac_roles ? "cluster-readonly" : null,
    var.create_default_rbac_roles ? "cluster-cicd" : null,
    join(", ", keys(var.custom_rbac_roles))
  ])
}

# -----------------------------------------------------------------------------
# Storage Class Outputs
# -----------------------------------------------------------------------------
output "default_storage_class_name" {
  description = "Name of the default storage class (if created)"
  value       = var.create_default_storage_class ? var.default_storage_class_name : null
}

# -----------------------------------------------------------------------------
# Cluster Autoscaler Outputs
# -----------------------------------------------------------------------------
output "cluster_autoscaler_service_account" {
  description = "Service account name for cluster autoscaler"
  value       = var.enable_cluster_autoscaler ? kubernetes_service_account_v1.cluster_autoscaler[0].metadata[0].name : null
}

output "cluster_autoscaler_deployment_name" {
  description = "Deployment name for cluster autoscaler"
  value       = var.enable_cluster_autoscaler ? kubernetes_deployment_v1.cluster_autoscaler[0].metadata[0].name : null
}

output "cluster_autoscaler_iam_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler IRSA"
  value       = var.enable_cluster_autoscaler ? module.cluster_autoscaler_irsa[0].iam_role_arn : null
}

output "cluster_autoscaler_image" {
  description = "Full image URL for cluster autoscaler (ECR or public)"
  value       = var.enable_cluster_autoscaler ? local.cluster_autoscaler_final_image : null
}

output "cluster_autoscaler_ecr_repository_url" {
  description = "ECR repository URL for cluster autoscaler image (if created)"
  value       = var.enable_cluster_autoscaler && var.cluster_autoscaler_use_ecr && var.cluster_autoscaler_ecr_repository_url == null ? aws_ecr_repository.cluster_autoscaler[0].repository_url : null
}

output "cluster_autoscaler_ecr_repository_arn" {
  description = "ECR repository ARN for cluster autoscaler image (if created)"
  value       = var.enable_cluster_autoscaler && var.cluster_autoscaler_use_ecr && var.cluster_autoscaler_ecr_repository_url == null ? aws_ecr_repository.cluster_autoscaler[0].arn : null
}

# Namespace Outputs
# -----------------------------------------------------------------------------
output "hyperswitch_namespace" {
  description = "Name of the Hyperswitch namespace (if created)"
  value       = var.enable_helm_deployments ? kubernetes_namespace_v1.hyperswitch[0].metadata[0].name : null
}

output "hyperswitch_helm_release_status" {
  description = "Status of the Hyperswitch Helm release (if deployed)"
  value       = var.enable_helm_deployments ? helm_release.hyperswitch_stack[0].status : null
}

# -----------------------------------------------------------------------------
# ECR Registry Secret Output
# -----------------------------------------------------------------------------
output "ecr_registry_secret_name" {
  description = "Name of the ECR registry secret (if created)"
  value       = var.enable_helm_deployments && var.create_ecr_registry_secret ? kubernetes_secret_v1.ecr_registry[0].metadata[0].name : null
}
