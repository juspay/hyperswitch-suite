# Foundation unit - every other GCP unit depends on it, directly or
# transitively. No `dependency` blocks here.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/vpc-network?ref=gcp-vpc-network-v0.1.0"
}

inputs = merge({
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network_name = "${include.root.locals.project_name}-${include.root.locals.environment.short}-vpc"
  routing_mode = "GLOBAL"

  # ---------------------------------------------------------------------------
  # Subnet CIDRs - one regional subnet per tier (GCP subnets already span
  # every zone in the region, unlike AWS's per-AZ subnets)
  # ---------------------------------------------------------------------------
  external_incoming_subnet_cidr = "${values.vpc_cidr_prefix}.0.0/24"
  management_subnet_cidr        = "${values.vpc_cidr_prefix}.1.0/24"

  gke_nodes_subnet_cidr             = "${values.vpc_cidr_prefix}.16.0/20"
  gke_pods_secondary_range_cidr     = values.gke_pods_secondary_range_cidr
  gke_services_secondary_range_cidr = values.gke_services_secondary_range_cidr

  database_subnet_cidr             = "${values.vpc_cidr_prefix}.2.0/24"
  locker_database_subnet_cidr      = "${values.vpc_cidr_prefix}.3.0/24"
  locker_server_subnet_cidr        = "${values.vpc_cidr_prefix}.4.0/24"
  memorystore_subnet_cidr          = "${values.vpc_cidr_prefix}.5.0/24"
  data_stack_subnet_cidr           = "${values.vpc_cidr_prefix}.6.0/24"
  incoming_envoy_subnet_cidr       = "${values.vpc_cidr_prefix}.7.0/24"
  outgoing_proxy_subnet_cidr       = "${values.vpc_cidr_prefix}.8.0/24"
  utils_subnet_cidr                = "${values.vpc_cidr_prefix}.9.0/24"
  serverless_connector_subnet_cidr = "${values.vpc_cidr_prefix}.10.0/28"

  custom_subnets = {}

  enable_flow_logs = false

  # ---------------------------------------------------------------------------
  # Cloud Router / Cloud NAT
  # ---------------------------------------------------------------------------
  router_asn           = 64514
  nat_min_ports_per_vm = 64

  # ---------------------------------------------------------------------------
  # Private Service Access (Cloud SQL / Memorystore)
  # ---------------------------------------------------------------------------
  private_service_access_prefix_length = 16

  # ---------------------------------------------------------------------------
  # Baseline firewall rules (cross-module rules live in ../firewall-rules,
  # deployed last)
  # ---------------------------------------------------------------------------
  vpc_internal_ranges = {
    primary  = "${values.vpc_cidr_prefix}.0.0/16"
    gke_pods = values.gke_pods_secondary_range_cidr
    gke_svcs = values.gke_services_secondary_range_cidr
  }
  enable_default_deny_ingress = true

  # Off by default - open egress (the module's own default) is the easy path for a
  # first install. Set values.network_options.enable_default_deny_egress = true to lock
  # GKE/other subnets down to no direct internet route, forcing egress through Squid's
  # allowlist (nat_subnetwork_tiers should then be narrowed to just the Squid tier, and
  # enable_psc_google_apis turned on so Artifact Registry/Google API calls still work).
  enable_default_deny_egress = try(values.network_options.enable_default_deny_egress, false)
  enable_psc_google_apis     = try(values.network_options.enable_psc_google_apis, false)
  nat_subnetwork_tiers       = try(values.network_options.nat_subnetwork_tiers, null)
  nat_log_filter             = try(values.network_options.nat_log_filter, "ERRORS_ONLY")

  labels = merge({
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    team        = "infra"
    managed_by  = "terraform"
  }, try(values.common_labels, {}))
}, try(values.cfg, {}))
