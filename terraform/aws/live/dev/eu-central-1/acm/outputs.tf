# ============================================================================
# ACM Certificate Outputs
# ============================================================================

output "acm_certificate_arns" {
  description = "Map of certificate names to their ARNs"
  value       = module.acm.certificate_arns
}

output "acm_certificates" {
  description = "Map of certificate names to their full output details"
  value       = module.acm.certificates
}

output "acm_certificate_domain_validation_options" {
  description = "Map of certificate names to their domain validation options"
  value       = module.acm.certificate_domain_validation_options
}

output "acm_certificate_statuses" {
  description = "Map of certificate names to their statuses"
  value       = module.acm.certificate_statuses
}

output "acm_validation_route53_record_fqdns" {
  description = "Map of certificate names to their Route53 validation record FQDNs"
  value       = module.acm.validation_route53_record_fqdns
}

output "acm_distinct_domain_names" {
  description = "Map of certificate names to their distinct domain names"
  value       = module.acm.distinct_domain_names
}
