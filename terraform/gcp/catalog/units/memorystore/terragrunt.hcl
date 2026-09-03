# Shared Hyperswitch cache/session store. Ratelimiter creates its own
# dedicated instance internally by default (see apps/ratelimiter).

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_id = "projects/mock/global/networks/mock-vpc"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/memorystore?ref=gcp-memorystore-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  authorized_network = dependency.vpc.outputs.network_id

  tier           = "STANDARD_HA"
  memory_size_gb = 5
  redis_version  = "REDIS_7_2"
  replica_count  = 0

  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  persistence_mode    = "RDB"
  rdb_snapshot_period = "TWENTY_FOUR_HOURS"

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "cache"
    managed_by  = "terraform"
  }
}
