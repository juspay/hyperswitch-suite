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

output "domain_filters" {
  description = "Domains external-dns is allowed to manage records for, as passed to var.domain_filters"
  value       = var.domain_filters
}

output "aws_zone_type" {
  description = "Zone type external-dns is scoped to (public, private, or empty for both), as passed to var.aws_zone_type"
  value       = var.aws_zone_type
}
