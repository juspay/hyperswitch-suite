# Shared VPC: one regional subnet per workload tier, Cloud Router + Cloud NAT
# for private egress, and a Private Service Access peering range for Cloud SQL /
# Memorystore.
#
# Baseline network-wide firewall rules (deny-all ingress, allow-internal, health
# checks, IAP) live here because they are internal to this module; cross-module
# rules belong in composition/firewall-rules.

module "vpc_network" {
  source  = "terraform-google-modules/network/google"
  version = "18.1.2"

  project_id   = var.project_id
  network_name = var.network_name
  routing_mode = var.routing_mode
  mtu          = var.mtu

  subnets          = local.subnets_list
  secondary_ranges = local.secondary_ranges

  ingress_rules = local.ingress_rules
  egress_rules  = local.egress_rules
}

# Cloud Router + Cloud NAT (egress for private subnets)
module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "9.0.0"

  name       = "${local.name_prefix}-router"
  project_id = var.project_id
  region     = var.region
  network    = module.vpc_network.network_self_link

  bgp = {
    asn = var.router_asn
  }
}

# Reserved static external IPs for Cloud NAT, only when nat_static_ip_count > 0.
# Passing them to cloud_nat's nat_ips is what flips the gateway from AUTO_ONLY
# to MANUAL_ONLY - the upstream module infers the mode from whether nat_ips is
# empty, so there is no separate toggle.
resource "google_compute_address" "nat" {
  count = var.nat_static_ip_count

  name         = "${local.name_prefix}-nat-ip-${count.index}"
  project      = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
  labels       = local.common_labels
}

module "cloud_nat" {
  source  = "terraform-google-modules/cloud-nat/google"
  version = "7.0.0"

  project_id = var.project_id
  region     = var.region
  router     = module.cloud_router.router.name
  name       = "${local.name_prefix}-nat"

  # Null (default) means ALL_SUBNETWORKS_ALL_IP_RANGES. Set it to restrict NAT
  # to specific tiers (e.g. only "outgoing-proxy"), leaving every other tier -
  # GKE nodes and pods included - with no NAT route at all.
  source_subnetwork_ip_ranges_to_nat = var.nat_subnetwork_tiers == null ? "ALL_SUBNETWORKS_ALL_IP_RANGES" : "LIST_OF_SUBNETWORKS"
  subnetworks                        = local.nat_subnetworks_list
  min_ports_per_vm                   = var.nat_min_ports_per_vm
  nat_ips                            = google_compute_address.nat[*].self_link

  log_config_enable = true
  log_config_filter = var.nat_log_filter
}

# Private Service Access (Cloud SQL / Memorystore standard-tier peering)
module "private_service_access" {
  source  = "terraform-google-modules/network/google//modules/private-service-access"
  version = "18.1.2"

  project_id    = var.project_id
  network_id    = module.vpc_network.network_id
  address_name  = "${local.name_prefix}-psa-range"
  prefix_length = var.private_service_access_prefix_length
}

# Private Service Connect for Google APIs (Artifact Registry, GCR, etc.), only
# when enable_psc_google_apis = true. Gives Google API traffic an internal-IP
# path that needs neither Cloud NAT nor a general internet route, which is what
# makes restricting egress safe without breaking image pulls.
module "psc_google_apis" {
  count   = var.enable_psc_google_apis ? 1 : 0
  source  = "terraform-google-modules/network/google//modules/private-service-connect"
  version = "18.1.2"

  project_id                   = var.project_id
  network_self_link            = module.vpc_network.network_self_link
  private_service_connect_ip   = var.psc_google_apis_ip
  private_service_connect_name = "${local.name_prefix}-psc-google-apis"
  # These forwarding rules have a stricter naming constraint than other GCP
  # resources: <=20 chars, lowercase alphanumerics only, starting with a letter.
  # name_prefix is both too long and hyphenated, so it cannot be reused here.
  forwarding_rule_name   = "${var.environment}pscapis"
  forwarding_rule_target = "all-apis"
}
