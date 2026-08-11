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

module "cloud_nat" {
  source  = "terraform-google-modules/cloud-nat/google"
  version = "7.0.0"

  project_id = var.project_id
  region     = var.region
  router     = module.cloud_router.router.name
  name       = "${local.name_prefix}-nat"

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  min_ports_per_vm                   = var.nat_min_ports_per_vm

  log_config_enable = true
  log_config_filter = "ERRORS_ONLY"
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
