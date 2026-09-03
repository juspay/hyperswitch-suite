include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link                 = "projects/mock/global/networks/mock-vpc"
    gke_nodes_subnet_self_link        = "projects/mock/regions/asia-south1/subnetworks/mock-gke-nodes"
    gke_pods_secondary_range_name     = "mock-gke-pods"
    gke_services_secondary_range_name = "mock-gke-services"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
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
  master_ipv4_cidr_block  = "172.16.0.0/28"

  # Falls back to an allow-all placeholder until include.root.locals.vpn_cidr_blocks
  # is populated with real office/VPN CIDRs - not safe to apply as-is.
  master_authorized_networks = (
    length(include.root.locals.vpn_cidr_blocks) > 0
    ? [for idx, cidr in include.root.locals.vpn_cidr_blocks : { cidr_block = cidr, display_name = "vpn-${idx}" }]
    : [{ cidr_block = "0.0.0.0/0", display_name = "placeholder-allow-all-REPLACE-ME" }]
  )

  deletion_protection = true

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

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }
}
