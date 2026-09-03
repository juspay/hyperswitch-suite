# Generic load balancer. The `var.internal` toggle switches between:
#   - external: global external HTTP(S) LB (terraform-google-modules/lb-http)
#   - internal: regional internal TCP/UDP LB (terraform-google-modules/lb-internal)
#
# DNS aliasing is left to an optional composition/cloud-dns call from the live
# layer, keeping the zone/record lifecycle independent of the load balancer's.

module "external_lb" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "14.2.0"

  count = var.internal ? 0 : 1

  project = var.project_id
  name    = local.name_prefix

  firewall_networks = [var.network]

  ssl                             = var.ssl
  managed_ssl_certificate_domains = var.managed_ssl_certificate_domains
  certificate_map                 = var.certificate_map
  https_redirect                  = var.ssl

  backends = var.backends

  labels = local.common_labels
}

module "internal_lb" {
  source  = "terraform-google-modules/lb-internal/google"
  version = "7.1.0"

  count = var.internal ? 1 : 0

  project    = var.project_id
  region     = var.region
  name       = local.name_prefix
  network    = var.network
  subnetwork = var.subnetwork

  ports = var.internal_lb_ports

  backends = var.internal_backends

  source_tags = var.internal_lb_source_tags
  target_tags = var.internal_lb_target_tags

  health_check = var.internal_lb_health_check

  labels = local.common_labels
}
