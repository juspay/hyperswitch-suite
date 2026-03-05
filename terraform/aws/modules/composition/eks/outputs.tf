# =============================================================================
# EKS Cluster Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Cluster Information
# -----------------------------------------------------------------------------
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_service_cidr" {
  description = "The CIDR block where Kubernetes pod and service IP addresses are assigned from"
  value       = try(module.eks.cluster_service_cidr, null)
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------
output "cluster_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

# -----------------------------------------------------------------------------
# Node Groups
# -----------------------------------------------------------------------------
output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = module.eks.eks_managed_node_groups
}

output "eks_managed_node_groups_iam_role_arn" {
  description = "IAM role ARN for EKS managed node groups"
  value       = try(module.eks.eks_managed_node_groups_iam_role_arn, null)
}

output "eks_managed_node_groups_iam_role_name" {
  description = "IAM role name for EKS managed node groups"
  value       = try(module.eks.eks_managed_node_groups_iam_role_name, null)
}

# -----------------------------------------------------------------------------
# IAM Role Outputs (for use with eks-kubernetes-resources module)
# -----------------------------------------------------------------------------
output "cluster_iam_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  value       = var.create_cluster_iam_role ? aws_iam_role.cluster[0].arn : var.cluster_iam_role_arn
}


output "ebs_csi_iam_role_arn" {
  description = "IAM role ARN for EBS CSI Driver"
  value       = module.ebs_csi_irsa.iam_role_arn
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

# -----------------------------------------------------------------------------
# Cross-Account Role Outputs
# -----------------------------------------------------------------------------
output "cross_account_role_arn" {
  description = "IAM role ARN for cross-account access (ArgoCD, Atlantis, etc.)"
  value       = var.create_cross_account_role ? aws_iam_role.cross_account[0].arn : null
}

output "cross_account_role_name" {
  description = "IAM role name for cross-account access"
  value       = var.create_cross_account_role ? aws_iam_role.cross_account[0].name : null
}

