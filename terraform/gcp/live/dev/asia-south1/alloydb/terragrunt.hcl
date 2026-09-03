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
  source = "../../../../modules/composition/alloydb"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network_id = dependency.vpc.outputs.network_id

  allocated_ip_range = "hyperswitch-dev-psa-range"

  database_version = "POSTGRES_15"

  master_username = "hyperswitch_admin"

  secret_manager = {
    create = true
  }

  primary_instance = {
    availability_type = "ZONAL"
    cpu_count         = 2

  }

  read_pool_instances = {}

  continuous_backup_enabled              = true
  continuous_backup_recovery_window_days = 14
  automated_backup_enabled               = true
  automated_backup_retention_count       = 14

  deletion_protection = false

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "database"
    managed_by  = "terraform"
  }
}
