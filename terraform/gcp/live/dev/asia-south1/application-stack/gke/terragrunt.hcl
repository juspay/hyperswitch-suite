include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {

  config_path = "../../vpc-network"

  mock_outputs = {
    network_name                      = "mock-vpc"
    subnets                           = { "asia-south1/hyperswitch-dev-gke-nodes" = { name = "mock-gke-nodes" } }
    gke_pods_secondary_range_name     = "mock-gke-pods"
    gke_services_secondary_range_name = "mock-gke-services"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "../../../../../modules/composition/gke"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  cluster_name_version = "01"

  regional = true

  network           = dependency.vpc.outputs.network_name
  subnetwork        = dependency.vpc.outputs.subnets["asia-south1/hyperswitch-dev-gke-nodes"].name
  ip_range_pods     = dependency.vpc.outputs.gke_pods_secondary_range_name
  ip_range_services = dependency.vpc.outputs.gke_services_secondary_range_name

  kubernetes_version = "latest"
  release_channel    = "REGULAR"

  enable_private_endpoint = false
  master_ipv4_cidr_block  = include.root.locals.gke_master_ipv4_cidr_block

  master_authorized_networks = include.root.locals.vpn_cidr_blocks

  deletion_protection = false

  create_service_account = false

  enable_node_auto_upgrade = false

  node_pools = [
    {
      name         = "system-pool"
      machine_type = include.root.locals.machine_types.gke_system_pool
      min_count    = 1
      max_count    = 2
      disk_size_gb = 100
      disk_type    = "pd-balanced"
      auto_repair  = true
      auto_upgrade = false
    },
    {
      name         = "app-pool"
      machine_type = include.root.locals.machine_types.gke_generic_compute
      min_count    = 1
      max_count    = 3
      disk_size_gb = 100
      disk_type    = "pd-balanced"
      auto_repair  = true
      auto_upgrade = false
    },
  ]

  node_pools_labels = {
    system-pool = { role = "system" }
    app-pool    = { role = "application" }
  }

  node_pools_taints = {
    system-pool = [
      { key = "components.hyperswitch.io/system", value = "true", effect = "NO_SCHEDULE" },
    ]
  }

  node_pools_tags = {
    system-pool = ["gke-node", "hyperswitch-dev", "gke-system-pool"]
    app-pool    = ["gke-node", "hyperswitch-dev", "gke-app-pool"]
  }

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }
}
