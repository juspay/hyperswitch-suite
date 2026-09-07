# Memorystore for Valkey, cluster mode — the GCP analogue of ElastiCache with
# engine = "valkey" / cluster_mode = "enabled". Replaces an earlier
# `memorystore` unit (classic Memorystore for Redis, which has no cluster
# support and is not on main).
#
# Requires Private Service Connect, NOT the PSA peering AlloyDB uses: the
# module creates a service_connection_policy on a DEDICATED subnet. The
# vpc-network unit already provisions a `memorystore` tier subnet for exactly
# this — PSC reserves addresses directly out of it, so nothing else may use it.
#
# auth and transit encryption are left at the module defaults (disabled),
# matching the application's lack of Redis AUTH/TLS support.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  # vpc-network keys its `subnets` output by "<region>/<name_prefix>-<tier>",
  # where name_prefix is "<project_name>-<environment>". Derived rather than
  # hardcoded so the unit works in any environment.
  memorystore_subnet_key = format(
    "%s/%s-%s-memorystore",
    include.root.locals.region,
    include.root.locals.project_name,
    include.root.locals.environment.short,
  )
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_name = "mock-vpc"
    subnets = {
      (local.memorystore_subnet_key) = { name = "mock-memorystore" }
    }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  # KEEP THIS PINNED TO A TAG THAT ACTUALLY CARRIES THE INPUTS BELOW.
  # Terragrunt passes `inputs` as TF_VAR_* environment variables, and
  # Terraform SILENTLY IGNORES a TF_VAR_ for a variable the module does not
  # declare — pointing this at an older tag does not fail, it just makes every
  # input below read as applied config while doing nothing.
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/memorystore-valkey?ref=gcp-memorystore-valkey-v0.1.0"
}


inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network      = dependency.vpc.outputs.network_name
  subnet_names = [dependency.vpc.outputs.subnets[local.memorystore_subnet_key].name]

  mode          = "CLUSTER"
  shard_count   = try(values.valkey.shard_count, 1)
  replica_count = try(values.valkey.replica_count, 1)
  node_type     = try(values.valkey.node_type, "SHARED_CORE_NANO")

  # Pinned rather than inherited from module defaults, so neither drifts with a
  # default bump. MULTI_ZONE is the analogue of AWS multi_az_enabled = true and
  # is IMMUTABLE — changing it later forces instance replacement.
  engine_version                = "VALKEY_8_0"
  zone_distribution_config_mode = try(values.valkey.zone_distribution_config_mode, "MULTI_ZONE")

  # ElastiCache folds persistence and backups into one concept (snapshots);
  # Memorystore splits them, so parity needs both blocks.
  persistence_config = {
    mode       = "RDB"
    rdb_config = { rdb_snapshot_period = "TWENTY_FOUR_HOURS" }
  }

  # retention 604800s = 7 days, matching the AWS units' snapshot_retention_limit.
  # start_time is the UTC hour. Times are UTC on both clouds.
  automated_backup_config = {
    retention  = "604800s"
    start_time = "23"
  }

  # Analogue of AWS maintenance_window = "mon:04:00-mon:05:00". Left unset,
  # Google picks the window — exactly the kind of thing that should not differ
  # silently between clouds.
  weekly_maintenance_window = [{
    day_of_week        = "MONDAY"
    start_time_hour    = "4"
    start_time_minutes = "0"
  }]

  # engine_configs (the parameter_group_name analogue) is deliberately unset:
  # Memorystore's defaults already agree with the stock ElastiCache group on
  # the parameter that matters (maxmemory-policy = volatile-lru). The knob is
  # plumbed if a custom group ever needs porting.

  deletion_protection_enabled = try(values.valkey.deletion_protection_enabled, true)

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "cache"
    engine      = "valkey"
    managed_by  = "terraform"
  }
}
