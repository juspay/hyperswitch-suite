# Shared Hyperswitch database. Grafana/Superposition/Locker create their own
# dedicated instances internally by default (see their own units) - this one
# is for the core hyperswitch-router database.

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
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/cloud-sql?ref=gcp-cloud-sql-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network_id = dependency.vpc.outputs.network_id

  instance_name = "${include.root.locals.project_name}-${include.root.locals.environment.short}-sql-pg"

  database_version    = "POSTGRES_15"
  tier                = "db-custom-2-8192"
  availability_type   = "REGIONAL"
  disk_size           = 100
  disk_autoresize     = true
  deletion_protection = true

  database_name   = "hyperswitch_db"
  master_username = "hyperswitch_admin"
  # master_password left unset -> module auto-generates one, exposed via the
  # (sensitive) generated_user_password output. Wire it into Secret Manager
  # out-of-band or via ../apps/external-secrets-operator once that's set up.

  retained_backups              = 30
  enable_point_in_time_recovery = true

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "database"
    managed_by  = "terraform"
  }
}
