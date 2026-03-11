# =========================================================================
# ACM CERTIFICATE OUTPUTS
# =========================================================================

output "certificate_arns" {
  description = "Map of certificate names to their ARNs"
  value       = { for name, cert in module.certificate : name => cert.acm_certificate_arn }
}

output "certificates" {
  description = "Map of certificate names to their full output details"
  value = {
    for name, cert in module.certificate : name => {
      arn                                 = cert.acm_certificate_arn
      domain_validation_options           = cert.acm_certificate_domain_validation_options
      status                              = cert.acm_certificate_status
      validation_route53_record_fqdns     = cert.validation_route53_record_fqdns
      distinct_domain_names               = cert.distinct_domain_names
      validation_domains                  = cert.validation_domains
      validation_emails                   = cert.acm_certificate_validation_emails
    }
  }
}

output "certificate_domain_validation_options" {
  description = "Map of certificate names to their domain validation options"
  value       = { for name, cert in module.certificate : name => cert.acm_certificate_domain_validation_options }
}

output "certificate_statuses" {
  description = "Map of certificate names to their statuses"
  value       = { for name, cert in module.certificate : name => cert.acm_certificate_status }
}

output "validation_route53_record_fqdns" {
  description = "Map of certificate names to their Route53 validation record FQDNs"
  value       = { for name, cert in module.certificate : name => cert.validation_route53_record_fqdns }
}

output "distinct_domain_names" {
  description = "Map of certificate names to their distinct domain names"
  value       = { for name, cert in module.certificate : name => cert.distinct_domain_names }
}
