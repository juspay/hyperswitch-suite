# One managed zone (public or private) plus its recordsets. Instantiate once
# per zone from the live layer.

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
