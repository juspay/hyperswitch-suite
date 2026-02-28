# EKS Cluster Outputs
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = try(module.eks.cluster_id, "")
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = try(module.eks.cluster_name, "")
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = try(module.eks.cluster_arn, "")
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = try(module.eks.cluster_endpoint, "")
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = try(module.eks.cluster_version, "")
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = try(module.eks.cluster_certificate_authority_data, "")
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = try(module.eks.cluster_oidc_issuer_url, "")
}

output "cluster_service_cidr" {
  description = "The CIDR block where Kubernetes pod and service IP addresses are assigned from"
  value       = try(module.eks.cluster_service_cidr, null)
}

output "cluster_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = try(module.eks.cluster_security_group_id, "")
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = try(module.eks.node_security_group_id, "")
}

output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = try(module.eks.eks_managed_node_groups, {})
}

output "cluster_autoscaler_iam_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler"
  value       = try(module.cluster_autoscaler_irsa.iam_role_arn, "")
}

output "ebs_csi_iam_role_arn" {
  description = "IAM role ARN for EBS CSI Driver"
  value       = try(module.ebs_csi_irsa.iam_role_arn, "")
}

output "eks_managed_node_groups_iam_role_arn" {
  description = "IAM role ARN for EKS managed node groups"
  value       = try(module.eks.eks_managed_node_groups_iam_role_arn, null)
}

output "eks_managed_node_groups_iam_role_name" {
  description = "IAM role name for EKS managed node groups"
  value       = try(module.eks.eks_managed_node_groups_iam_role_name, null)
}
