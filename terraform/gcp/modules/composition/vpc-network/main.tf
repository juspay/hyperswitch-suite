# ============================================================================
# VPC Network (GCP equivalent of composition/vpc-network)
# ============================================================================
# Builds the shared VPC: one regional subnet per workload tier, Cloud Router
# + Cloud NAT for private egress, and a Private Service Access peering range
# for Cloud SQL / Memorystore. Baseline network-wide firewall rules (deny-all
# ingress, allow-internal, allow health checks, allow IAP) live here because
# they are internal to this module; cross-module rules belong in
# composition/firewall-rules (see that module's README).
#
# GCP has no NACL equivalent (stateful firewall rules make them redundant)
# and no per-AZ subnet fan-out (GCP subnets are already regional), so this
# module is intentionally flatter than its AWS counterpart.
#
# Usage:
#   module "vpc_network" {
#     source = "../../modules/composition/vpc-network"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     network_name = "hyperswitch-dev-vpc"
#     region       = "europe-west1"
#
#     external_incoming_subnet_cidr    = "10.0.0.0/24"
#     management_subnet_cidr           = "10.0.1.0/24"
#     gke_nodes_subnet_cidr            = "10.0.16.0/20"
#     gke_pods_secondary_range_cidr    = "10.4.0.0/14"
#     gke_services_secondary_range_cidr = "10.8.0.0/20"
#     ...
#   }
# ============================================================================

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

# ==============================================================================
# Cloud Router + Cloud NAT (egress for private subnets, replaces AWS NAT GW)
# ==============================================================================
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

# Reserved static external IPs for Cloud NAT, only created when
# nat_static_ip_count > 0. Passing these into cloud_nat's nat_ips below is
# what flips the NAT gateway from GCP's default AUTO_ONLY (ephemeral,
# Google-chosen IPs) to MANUAL_ONLY (stable, customer-controlled IPs) - the
# terraform-google-modules/cloud-nat/google module infers
# nat_ip_allocate_option from whether nat_ips is empty, so no separate mode
# toggle is needed here.
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

  # nat_subnetwork_tiers == null (default) -> ALL_SUBNETWORKS_ALL_IP_RANGES,
  # identical to this module's original unconditional behavior. Set it to
  # restrict NAT to specific tiers (e.g. just "outgoing-proxy") so other
  # tiers - GKE nodes/pods included - get no NAT route at all, matching
  # AWS's eks-worker-s3-only route table pattern.
  source_subnetwork_ip_ranges_to_nat = var.nat_subnetwork_tiers == null ? "ALL_SUBNETWORKS_ALL_IP_RANGES" : "LIST_OF_SUBNETWORKS"
  subnetworks                        = local.nat_subnetworks_list
  min_ports_per_vm                   = var.nat_min_ports_per_vm
  nat_ips                            = google_compute_address.nat[*].self_link

  log_config_enable = true
  log_config_filter = var.nat_log_filter
}

# ==============================================================================
# Private Service Access (Cloud SQL / Memorystore standard-tier peering)
# ==============================================================================
module "private_service_access" {
  source  = "terraform-google-modules/network/google//modules/private-service-access"
  version = "18.1.2"

  project_id    = var.project_id
  network_id    = module.vpc_network.network_id
  address_name  = "${local.name_prefix}-psa-range"
  prefix_length = var.private_service_access_prefix_length
}

# ==============================================================================
# Private Service Connect for Google APIs (Artifact Registry, GCR, etc.)
# ==============================================================================
# Only created when enable_psc_google_apis = true. Gives Google API traffic
# an internal-IP path inside the VPC that doesn't depend on Cloud NAT or a
# general internet route - what makes it safe to restrict NAT/egress
# (nat_subnetwork_tiers, enable_default_deny_egress) without breaking image
# pulls. AWS's equivalent is the ecr_api/ecr_dkr interface VPC endpoints in
# the AWS composition/vpc-network module - same idea, GCP-native mechanism.
module "psc_google_apis" {
  count   = var.enable_psc_google_apis ? 1 : 0
  source  = "terraform-google-modules/network/google//modules/private-service-connect"
  version = "18.1.2"

  project_id                   = var.project_id
  network_self_link            = module.vpc_network.network_self_link
  private_service_connect_ip   = var.psc_google_apis_ip
  private_service_connect_name = "${local.name_prefix}-psc-google-apis"
  # PSC-for-Google-APIs forwarding rules have a stricter naming constraint
  # than normal GCP resources: <=20 chars, lowercase letters and numbers
  # only, no hyphens, must start with a letter. name_prefix (e.g.
  # "hyperswitch-dev") is both too long and has hyphens, so this can't
  # reuse it the way every other resource in this module does.
  forwarding_rule_name   = "${var.environment}pscapis"
  forwarding_rule_target = "all-apis"
}
