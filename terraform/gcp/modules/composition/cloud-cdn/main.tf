# ============================================================================
# Cloud CDN (GCP equivalent of composition/cloudfront)
# ============================================================================
# One global external HTTP(S) load balancer per distribution with Cloud CDN
# enabled on its backends, plus a GCS log bucket, matching the AWS module's
# CloudFront distribution + S3 log bucket shape. Origins can be Cloud
# Storage buckets (via `backend_buckets`) or Compute/Serverless backends
# (via `backend_services`, reusing the same backend map shape as
# composition/load-balancer).
#
# CloudFront Functions have no Cloud CDN equivalent (Cloud CDN has no
# request/response edge-compute hook); the nearest GCP-native path for
# request rewriting is a Cloud Run/Cloud Functions origin placed in front of
# the real origin, which is out of scope for this module. See
# terraform/gcp/modules/README.md.
#
# Usage:
#   module "cloud_cdn" {
#     source = "../../modules/composition/cloud-cdn"
#
#     project_id  = "hyperswitch-dev"
#     environment = "dev"
#     name_override = "assets"
#
#     backend_buckets = {
#       assets = { bucket_name = module.assets_bucket.name, enable_cdn = true }
#     }
#     managed_ssl_certificate_domains = ["assets.dev.hyperswitch.example.com"]
#   }
# ============================================================================

module "log_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  count = var.enable_logging ? 1 : 0

  project_id    = var.project_id
  name          = "${local.name_prefix}-logs"
  location      = var.log_bucket_location
  force_destroy = false

  versioning         = true
  bucket_policy_only = true

  lifecycle_rules = [{
    action    = { type = "Delete" }
    condition = { age = var.log_retention_days }
  }]

  labels = local.common_labels
}

resource "google_compute_backend_bucket" "this" {
  for_each = var.backend_buckets

  project     = var.project_id
  name        = "${local.name_prefix}-${each.key}"
  bucket_name = each.value.bucket_name
  enable_cdn  = try(each.value.enable_cdn, true)

  cdn_policy {
    cache_mode        = try(each.value.cache_mode, "CACHE_ALL_STATIC")
    default_ttl       = try(each.value.default_ttl, 3600)
    client_ttl        = try(each.value.client_ttl, 3600)
    max_ttl           = try(each.value.max_ttl, 86400)
    negative_caching  = try(each.value.negative_caching, true)
    serve_while_stale = try(each.value.serve_while_stale, 86400)
  }
}

resource "google_compute_url_map" "this" {
  project         = var.project_id
  name            = local.name_prefix
  default_service = values(google_compute_backend_bucket.this)[0].id
}

resource "google_compute_target_https_proxy" "this" {
  count = var.ssl ? 1 : 0

  project = var.project_id
  name    = "${local.name_prefix}-https-proxy"
  url_map = google_compute_url_map.this.id

  ssl_certificates = var.certificate_map == null ? [google_compute_managed_ssl_certificate.this[0].id] : null
  certificate_map  = var.certificate_map != null ? "//certificatemanager.googleapis.com/${var.certificate_map}" : null
}

resource "google_compute_managed_ssl_certificate" "this" {
  count = var.ssl && var.certificate_map == null ? 1 : 0

  project = var.project_id
  name    = "${local.name_prefix}-cert"

  managed {
    domains = var.managed_ssl_certificate_domains
  }
}

resource "google_compute_global_address" "this" {
  project = var.project_id
  name    = "${local.name_prefix}-ip"
}

resource "google_compute_global_forwarding_rule" "https" {
  count = var.ssl ? 1 : 0

  project    = var.project_id
  name       = "${local.name_prefix}-https"
  target     = google_compute_target_https_proxy.this[0].id
  port_range = "443"
  ip_address = google_compute_global_address.this.address
}

resource "google_compute_target_http_proxy" "this" {
  count = var.http_redirect_to_https || !var.ssl ? 1 : 0

  project = var.project_id
  name    = "${local.name_prefix}-http-proxy"
  url_map = var.ssl ? google_compute_url_map.https_redirect[0].id : google_compute_url_map.this.id
}

resource "google_compute_url_map" "https_redirect" {
  count = var.ssl && var.http_redirect_to_https ? 1 : 0

  project = var.project_id
  name    = "${local.name_prefix}-https-redirect"

  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

resource "google_compute_global_forwarding_rule" "http" {
  count = var.http_redirect_to_https || !var.ssl ? 1 : 0

  project    = var.project_id
  name       = "${local.name_prefix}-http"
  target     = google_compute_target_http_proxy.this[0].id
  port_range = "80"
  ip_address = google_compute_global_address.this.address
}
