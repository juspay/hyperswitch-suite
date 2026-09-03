# Creates its own dedicated Memorystore instance internally by default
# (create_redis = true) - still needs the VPC network to peer it to.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../../vpc-network"

  mock_outputs = {
    network_id   = "projects/mock/global/networks/mock-vpc"
    network_name = "mock-vpc"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "gke" {
  config_path = "../../gke"

  mock_outputs = {
    cluster_name = "mock-cluster"
    location     = "asia-south1"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/ratelimiter?ref=gcp-apps-ratelimiter-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location

  create_redis         = true
  authorized_network   = dependency.vpc.outputs.network_id
  redis_tier           = "STANDARD_HA"
  redis_memory_size_gb = 1

  create_firewall_rule = true
  network_name         = dependency.vpc.outputs.network_name
  # Shared with ../../vpc-network's gke_pods_secondary_range_cidr value -
  # both units read the same values.gke_pods_secondary_range_cidr, so they
  # can't drift out of sync the way the pre-catalog literal copy could.
  gke_pods_cidr = values.gke_pods_secondary_range_cidr

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
