include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../../vpc-network"

  mock_outputs = {
    network_self_link                 = "projects/mock/global/networks/mock-vpc"
    gke_nodes_subnet_self_link        = "projects/mock/regions/asia-south1/subnetworks/mock-gke-nodes"
    gke_pods_secondary_range_name     = "mock-gke-pods"
    gke_services_secondary_range_name = "mock-gke-services"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

locals {
  # Per-environment overrides, passed by the stack as this unit's `cfg` value.
  # Defaults below are what the live dev environment runs.
  cfg = try(values.cfg, {})
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/gke?ref=gcp-gke-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  cluster_name = "${include.root.locals.project_name}-${include.root.locals.environment.short}-gke"
  regional     = true

  network           = dependency.vpc.outputs.network_self_link
  subnetwork        = dependency.vpc.outputs.gke_nodes_subnet_self_link
  ip_range_pods     = dependency.vpc.outputs.gke_pods_secondary_range_name
  ip_range_services = dependency.vpc.outputs.gke_services_secondary_range_name

  kubernetes_version = "latest"
  release_channel    = "REGULAR"

  enable_private_endpoint = false
  master_ipv4_cidr_block  = try(values.gke_master_ipv4_cidr_block, "172.16.0.0/28")

  # Passed straight through as { cidr_block, display_name } pairs — NOT
  # synthesized from a flat CIDR list. The GKE API does not guarantee
  # cidr_blocks ordering, so zipping a flat list against generated "vpn-N"
  # names silently renames every entry away from its real office/vpn grouping
  # on the next apply (same CIDRs, no access-control change, but a misleading
  # remove+re-add on all of them).
  #
  # Empty means allow-all, which is NOT safe to apply — populate it.
  master_authorized_networks = (
    length(include.root.locals.vpn_cidr_blocks) > 0
    ? include.root.locals.vpn_cidr_blocks
    : [{ cidr_block = "0.0.0.0/0", display_name = "placeholder-allow-all-REPLACE-ME" }]
  )

  deletion_protection = try(values.gke_deletion_protection, true)

  node_pools = [
    {
      name         = "system-pool"
      machine_type = values.machine_types.gke_system_pool
      min_count    = 1
      max_count    = 5
      disk_size_gb = 100
      disk_type    = "pd-balanced"
      auto_repair  = true
      auto_upgrade = true
    },
    {
      name         = "generic-compute"
      machine_type = values.machine_types.gke_generic_compute
      min_count    = 1
      max_count    = 10
      disk_size_gb = 100
      disk_type    = "pd-balanced"
      auto_repair  = true
      auto_upgrade = true
    },
  ]

  # "01" keeps room for a blue/green cluster rebuild without renaming.
  cluster_name_version = try(local.cfg.cluster_name_version, "01")

  # false where the node service account is managed outside this unit.
  create_service_account = try(local.cfg.create_service_account, true)

  # Auto-upgrade off pins the control plane/node version to a deliberate
  # rollout rather than Google's schedule.
  enable_node_auto_upgrade = try(local.cfg.enable_node_auto_upgrade, true)

  # Keyed by node-pool name. node_pools_tags feed the firewall-rules unit's
  # target_tags, so the two must agree.
  node_pools_labels = try(local.cfg.node_pools_labels, {})
  node_pools_taints = try(local.cfg.node_pools_taints, {})
  node_pools_tags   = try(local.cfg.node_pools_tags, {})


  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }
}
