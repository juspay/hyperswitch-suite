# =============================================================================
# EKS Kubernetes Resources Module - Outputs (Wrapper)
# =============================================================================
# This wrapper passes all outputs through from the implementation module.
# See ../backup/eks-kubernetes-resources/outputs.tf for detailed descriptions.
# =============================================================================

# -----------------------------------------------------------------------------
# RBAC Outputs
# -----------------------------------------------------------------------------
output "rbac_roles_created" {
  description = "List of RBAC roles created"
  value       = module.eks_kubernetes_resources.rbac_roles_created
}

# -----------------------------------------------------------------------------
# Storage Class Outputs
# -----------------------------------------------------------------------------
output "default_storage_class_name" {
  description = "Name of the default storage class (if created)"
  value       = module.eks_kubernetes_resources.default_storage_class_name
}

# -----------------------------------------------------------------------------
# Cluster Autoscaler Outputs
# -----------------------------------------------------------------------------
output "cluster_autoscaler_service_account" {
  description = "Service account name for cluster autoscaler"
  value       = module.eks_kubernetes_resources.cluster_autoscaler_service_account
}

output "cluster_autoscaler_deployment_name" {
  description = "Deployment name for cluster autoscaler"
  value       = module.eks_kubernetes_resources.cluster_autoscaler_deployment_name
}

output "cluster_autoscaler_iam_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler IRSA"
  value       = module.eks_kubernetes_resources.cluster_autoscaler_iam_role_arn
}

output "cluster_autoscaler_image" {
  description = "Full image URL for cluster autoscaler (ECR or public)"
  value       = module.eks_kubernetes_resources.cluster_autoscaler_image
}

output "cluster_autoscaler_ecr_repository_url" {
  description = "ECR repository URL for cluster autoscaler image (if created)"
  value       = module.eks_kubernetes_resources.cluster_autoscaler_ecr_repository_url
}

output "cluster_autoscaler_ecr_repository_arn" {
  description = "ECR repository ARN for cluster autoscaler image (if created)"
  value       = module.eks_kubernetes_resources.cluster_autoscaler_ecr_repository_arn
}

# -----------------------------------------------------------------------------
# Namespace Outputs
# -----------------------------------------------------------------------------
output "hyperswitch_namespace" {
  description = "Name of the Hyperswitch namespace (if created)"
  value       = module.eks_kubernetes_resources.hyperswitch_namespace
}

output "hyperswitch_helm_release_status" {
  description = "Status of the Hyperswitch Helm release (if deployed)"
  value       = module.eks_kubernetes_resources.hyperswitch_helm_release_status
}

# -----------------------------------------------------------------------------
# ECR Registry Secret Output
# -----------------------------------------------------------------------------
output "ecr_registry_secret_name" {
  description = "Name of the ECR registry secret (if created)"
  value       = module.eks_kubernetes_resources.ecr_registry_secret_name
}
