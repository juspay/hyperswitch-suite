# Foundation unit — every other GCP unit depends on it, directly or
# transitively. No `dependency` blocks here.
#
# Subnet addressing works two ways:
#
#   * Greenfield — pass only `vpc_cidr_prefix` and every tier is derived from
#     it on a fixed layout. This is what a new environment should use.
#   * Adoption — pass `values.subnet_cidrs` to pin any tier explicitly. An
#     environment whose addressing was allocated by hand (as the live dev VPC
#     was) cannot be reproduced by the formula, and applying the formula
#     against its state would plan to recreate every subnet. Override the
#     tiers that differ; unset ones still fall back to the formula.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/vpc-network?ref=gcp-vpc-network-v0.1.0"
}

locals {
  prefix = values.vpc_cidr_prefix
  cidrs  = try(values.subnet_cidrs, {})
  net    = try(values.network_options, {})
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network_name = try(
    local.net.network_name,
    "${include.root.locals.project_name}-${include.root.locals.environment.short}-vpc",
  )
  routing_mode = try(local.net.routing_mode, "GLOBAL")

  # ---------------------------------------------------------------------------
  # Subnet CIDRs — one regional subnet per tier (GCP subnets already span every
  # zone in the region, unlike AWS's per-AZ subnets).
  # ---------------------------------------------------------------------------
  external_incoming_subnet_cidr = try(local.cidrs.external_incoming, "${local.prefix}.0.0/24")
  management_subnet_cidr        = try(local.cidrs.management, "${local.prefix}.1.0/24")

  gke_nodes_subnet_cidr             = try(local.cidrs.gke_nodes, "${local.prefix}.16.0/20")
  gke_pods_secondary_range_cidr     = values.gke_pods_secondary_range_cidr
  gke_services_secondary_range_cidr = values.gke_services_secondary_range_cidr

  database_subnet_cidr             = try(local.cidrs.database, "${local.prefix}.2.0/24")
  locker_database_subnet_cidr      = try(local.cidrs.locker_database, "${local.prefix}.3.0/24")
  locker_server_subnet_cidr        = try(local.cidrs.locker_server, "${local.prefix}.4.0/24")
  memorystore_subnet_cidr          = try(local.cidrs.memorystore, "${local.prefix}.5.0/24")
  data_stack_subnet_cidr           = try(local.cidrs.data_stack, "${local.prefix}.6.0/24")
  incoming_envoy_subnet_cidr       = try(local.cidrs.incoming_envoy, "${local.prefix}.7.0/24")
  outgoing_proxy_subnet_cidr       = try(local.cidrs.outgoing_proxy, "${local.prefix}.8.0/24")
  utils_subnet_cidr                = try(local.cidrs.utils, "${local.prefix}.9.0/24")
  serverless_connector_subnet_cidr = try(local.cidrs.serverless_connector, "${local.prefix}.10.0/28")

  custom_subnets = try(local.net.custom_subnets, {})

  enable_flow_logs = try(local.net.enable_flow_logs, false)

  # ---------------------------------------------------------------------------
  # Cloud Router / Cloud NAT
  # ---------------------------------------------------------------------------
  router_asn           = try(local.net.router_asn, 64514)
  nat_min_ports_per_vm = try(local.net.nat_min_ports_per_vm, 64)

  # Restrict NAT to the tiers that actually need egress. Unset, the module
  # NATs every tier — fine greenfield, wrong for an environment that
  # deliberately routes egress through the squid proxy only.
  nat_subnetwork_tiers = try(local.net.nat_subnetwork_tiers, null)
  nat_log_filter       = try(local.net.nat_log_filter, null)

  # ---------------------------------------------------------------------------
  # Private Service Access (AlloyDB / Memorystore) and PSC for Google APIs
  # ---------------------------------------------------------------------------
  private_service_access_prefix_length = try(local.net.private_service_access_prefix_length, 16)
  enable_psc_google_apis               = try(local.net.enable_psc_google_apis, false)

  # ---------------------------------------------------------------------------
  # Baseline firewall rules (cross-unit rules live in ../firewall-rules)
  # ---------------------------------------------------------------------------
  # `psa` belongs here once the PSA range is reserved — without it, egress to
  # AlloyDB is not permitted by the internal-egress rule.
  vpc_internal_ranges = try(local.net.vpc_internal_ranges, {
    primary  = "${local.prefix}.0.0/16"
    gke_pods = values.gke_pods_secondary_range_cidr
    gke_svcs = values.gke_services_secondary_range_cidr
  })

  enable_default_deny_ingress = try(local.net.enable_default_deny_ingress, true)
  enable_default_deny_egress  = try(local.net.enable_default_deny_egress, false)

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    team        = "infra"
    managed_by  = "terraform"
  }
}
