include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_name = "mock-vpc"
    subnets      = { "asia-south1/hyperswitch-dev-memorystore" = { name = "mock-memorystore" } }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "../../../../modules/composition/memorystore-valkey"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network      = dependency.vpc.outputs.network_name
  subnet_names = [dependency.vpc.outputs.subnets["asia-south1/hyperswitch-dev-memorystore"].name]

  mode          = "CLUSTER"
  shard_count   = 1
  replica_count = 1
  node_type     = "SHARED_CORE_NANO"

  engine_version                = "VALKEY_8_0"
  zone_distribution_config_mode = "MULTI_ZONE"

  persistence_config = {
    mode       = "RDB"
    rdb_config = { rdb_snapshot_period = "TWENTY_FOUR_HOURS" }
  }

  automated_backup_config = {
    retention  = "604800s"
    start_time = "23"
  }

  weekly_maintenance_window = [{
    day_of_week        = "MONDAY"
    start_time_hour    = "4"
    start_time_minutes = "0"
  }]

  deletion_protection_enabled = false

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "cache"
    engine      = "valkey"
    managed_by  = "terraform"
  }
}
