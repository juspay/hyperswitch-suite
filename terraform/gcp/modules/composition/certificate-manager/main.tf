# Certificate Manager. No registry module covers it, so this wraps the raw
# resources: one entry in var.certificates, one managed certificate out.
#
# Google-managed certificates need their DNS authorization records published
# (see the `dns_authorization_records` output) before validation completes.
# This module does not create those records - composition/cloud-dns owns them.
#
# A classic google_compute_managed_ssl_certificate is also created per
# certificate, for callers attaching to a classic External HTTPS LB target proxy.

resource "google_certificate_manager_dns_authorization" "this" {
  for_each = toset(local.dns_authorization_domains)

  project  = var.project_id
  name     = replace("${var.environment}-${var.project_name}-${each.key}", ".", "-")
  domain   = each.key
  location = "global"
  type     = var.dns_authorization_type
  labels   = local.common_labels
}

resource "google_certificate_manager_certificate" "this" {
  for_each = var.certificates

  project  = var.project_id
  name     = "${var.environment}-${var.project_name}-${each.key}-cert"
  location = "global"
  labels   = merge(local.common_labels, try(each.value.labels, {}))

  managed {
    domains = concat([each.value.domain_name], each.value.subject_alternative_names)
    dns_authorizations = [
      for domain in concat([each.value.domain_name], each.value.subject_alternative_names) :
      google_certificate_manager_dns_authorization.this[domain].id
      if each.value.validation_method == "DNS"
    ]
  }
}

resource "google_certificate_manager_certificate_map" "this" {
  for_each = var.create_certificate_map ? var.certificates : {}

  project = var.project_id
  name    = "${var.environment}-${var.project_name}-${each.key}-map"
  labels  = local.common_labels
}

resource "google_certificate_manager_certificate_map_entry" "this" {
  for_each = var.create_certificate_map ? var.certificates : {}

  project      = var.project_id
  name         = "${var.environment}-${var.project_name}-${each.key}-map-entry"
  map          = google_certificate_manager_certificate_map.this[each.key].name
  certificates = [google_certificate_manager_certificate.this[each.key].id]
  hostname     = each.value.domain_name
  labels       = local.common_labels
}

# Classic managed SSL certificate, for classic External HTTPS LB target proxies
resource "google_compute_managed_ssl_certificate" "this" {
  for_each = { for key, cert in var.certificates : key => cert if cert.create_classic_ssl_certificate }

  project = var.project_id
  name    = "${var.environment}-${var.project_name}-${each.key}-classic-cert"

  managed {
    domains = concat([each.value.domain_name], each.value.subject_alternative_names)
  }
}
