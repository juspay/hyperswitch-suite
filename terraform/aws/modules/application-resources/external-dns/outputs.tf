# ============================================================================
# Outputs
# ============================================================================

output "external_dns_role_arn" {
  description = "The ARN of the external-dns IAM role"
  value       = module.external_dns_irsa.iam_role_arn
}

output "external_dns_service_account" {
  description = "Service Account Name of external-dns"
  value       = kubernetes_service_account_v1.external_dns[*].metadata[0].name
}

output "region" {
  description = "AWS region where resources are created"
  value       = data.aws_region.current.region
}
