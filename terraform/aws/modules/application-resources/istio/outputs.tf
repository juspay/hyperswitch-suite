# ============================================================================
# Outputs
# ============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = var.eks_cluster_name
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "lb_security_group_id" {
  description = "ID of the created load balancer security group"
  value       = aws_security_group.lb_security_group[*].id
}

output "host_domains" {
  description = "List of host domains for Istio Gateway"
  value       = var.host_domains
}

