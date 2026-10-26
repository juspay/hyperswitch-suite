# ============================================================================
# Outputs
# ============================================================================

output "role_arn" {
  description = "ARN of the Cluster Autoscaler IAM role, consumed by the Helm chart service account annotation"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the Cluster Autoscaler IAM role"
  value       = aws_iam_role.this.name
}

output "policy_arn" {
  description = "ARN of the Cluster Autoscaler IAM policy"
  value       = aws_iam_policy.cluster_autoscaler.arn
}

output "service_account_name" {
  description = "Name of the service account the IAM role is scoped to"
  value       = var.service_account_name
}

output "namespace" {
  description = "Namespace the Cluster Autoscaler is deployed into"
  value       = var.namespace
}

output "region" {
  description = "AWS region where resources are created"
  value       = data.aws_region.current.region
}
