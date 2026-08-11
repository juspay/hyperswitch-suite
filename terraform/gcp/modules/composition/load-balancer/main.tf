# ============================================================================
# Generic Load Balancer (GCP equivalent of composition/load-balancer)
# ============================================================================
# One `var.internal` toggle switches between:
#   - external: Global external HTTP(S) Load Balancer (terraform-google-modules/lb-http)
#   - internal: Regional internal TCP/UDP Load Balancer (terraform-google-modules/lb-internal)
# mirroring the AWS module's single ALB module with an internal/external
# toggle. DNS aliasing is handled by an optional composition/cloud-dns call
# from the live layer, not by this module, to keep the zone/record lifecycle
# independent of the load balancer's.
#
# Usage (external):
#   module "load_balancer" {
#     source = "../../modules/composition/load-balancer"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     name_override = "api"
#     internal     = false
#
#     backends = {
#       default = {
#         groups = [{ group = module.some_umig.self_links[0] }]
#         health_check = { request_path = "/health", port = 8080 }
#         log_config   = { enable = true, sample_rate = 1.0 }
#       }
#     }
#   }
# ============================================================================

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
