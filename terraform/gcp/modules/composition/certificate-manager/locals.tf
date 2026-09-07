locals {
  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "certificate-manager"
      "managed_by"  = "terraform"
    },
    var.labels
  )

  # Flatten {cert_key -> domain_name + sans} into one DNS authorization per
  # unique domain, since google_certificate_manager_dns_authorization is
  # per-domain, not per-certificate.
  dns_authorization_domains = distinct(flatten([
    for key, cert in var.certificates : concat([cert.domain_name], cert.subject_alternative_names)
    if cert.validation_method == "DNS"
  ]))
}
