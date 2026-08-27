# ============================================================================
# Cloud DNS (GCP equivalent of composition/route53)
# ============================================================================
# One managed zone (public or private) per module call plus its recordsets,
# matching the AWS module's zone+records shape. Instantiate this module once
# per zone from the live layer, same as composition/route53.
#
# Usage:
#   module "cloud_dns_public" {
#     source = "../../modules/composition/cloud-dns"
#
#     project_id  = "hyperswitch-dev"
#     environment = "dev"
#     zone_name   = "hyperswitch-dev-public"
#     domain      = "dev.hyperswitch.example.com."
#     type        = "public"
#
#     recordsets = [
#       { name = "api", type = "A", ttl = 300, records = ["203.0.113.10"] },
#     ]
#   }
# ============================================================================

module "cloud_dns" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "7.1.0"

  project_id = var.project_id
  name       = var.zone_name
  domain     = var.domain
  type       = var.type

  private_visibility_config_networks = var.private_visibility_config_networks

  dnssec_config = var.enable_dnssec ? {
    kind          = "dns#managedZoneDnsSecConfig"
    non_existence = "nsec3"
    state         = "on"
  } : null

  recordsets = var.recordsets

  labels = local.common_labels
}
