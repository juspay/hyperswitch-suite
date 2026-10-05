# Memorystore for Redis Cluster - the Redis-engine sibling of the
# memorystore-valkey unit, for environments that want Redis instead of
# Valkey. Not wired into any stack yet - this unit stands alone, same as
# memorystore-valkey did before it was picked up by the dev stack; offering
# an actual Valkey-vs-Redis choice at the stack level is follow-up work.
#
# Requires Private Service Connect, NOT the PSA peering AlloyDB uses: the
# module creates a service_connection_policy on a DEDICATED subnet. Reuses
# the same `memorystore` tier subnet the valkey unit uses - the two are
# meant to be mutually exclusive per environment, never both deployed into
# the same stack at once, so there's no contention over that subnet's
# reserved PSC addresses.
#
# auth and transit encryption are left at the module defaults (disabled),
# matching the application's lack of Redis AUTH/TLS support.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# Defaults to disabled (memorystore-valkey is the incumbent engine), so a
# stack opts in explicitly by setting redis_enabled = true. Independent of
# memorystore-valkey's own valkey_enabled - nothing stops a stack setting
# both true, but both units reserve PSC addresses from the same dedicated
# `memorystore` subnet, so running both at once in the same environment
# will hit a real conflict there.
exclude {
  if      = !try(values.redis_enabled, false)
  actions = ["all"]
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
  # declare - pointing this at an older tag does not fail, it just makes every
  # input below read as applied config while doing nothing.
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/memorystore-redis?ref=gcp-memorystore-redis-v0.1.0"
}

inputs = merge({
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network      = dependency.vpc.outputs.network_name
  subnet_names = [dependency.vpc.outputs.subnets[local.memorystore_subnet_key].name]

  shard_count   = try(values.redis.shard_count, 1)
  replica_count = try(values.redis.replica_count, 0)
  node_type     = try(values.redis.node_type, "REDIS_SHARED_CORE_NANO")

  # Pinned rather than inherited from module defaults, so it doesn't drift
  # with a default bump. MULTI_ZONE is the analogue of AWS multi_az_enabled =
  # true and is IMMUTABLE - changing it later forces instance replacement.
  zone_distribution_config_mode = try(values.redis.zone_distribution_config_mode, "MULTI_ZONE")

  # Unlike memorystore-valkey, this resource has no automated_backup_config -
  # the installed module version doesn't expose scheduled off-instance
  # backups for Redis Cluster yet. In-instance RDB persistence is the only
  # durability knob available; set here rather than left at the API default
  # (PERSISTENCE_MODE_UNSPECIFIED) so data survives a node restart.
  persistence_config = {
    mode       = "RDB"
    rdb_config = { rdb_snapshot_period = "TWENTY_FOUR_HOURS" }
  }

  # Analogue of AWS maintenance_window = "mon:04:00-mon:05:00". Left unset,
  # Google picks the window - exactly the kind of thing that should not differ
  # silently between clouds. Unlike memorystore-valkey's weekly_maintenance_window
  # (a list, for that submodule's own interface reasons), this resource takes a
  # single object with different field names (day_of_the_week/hours/minutes).
  weekly_maintenance_window = {
    day_of_the_week = "MONDAY"
    hours           = "4"
    minutes         = "0"
  }

  # redis_configs (the parameter_group_name analogue) is deliberately unset:
  # Memorystore's defaults already agree with the stock ElastiCache group on
  # the parameter that matters (maxmemory-policy = volatile-lru). The knob is
  # plumbed if a custom group ever needs porting.

  deletion_protection_enabled = try(values.redis.deletion_protection_enabled, true)

  labels = merge({
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "cache"
    engine      = "redis"
    managed_by  = "terraform"
  }, try(values.common_labels, {}))
}, try(values.cfg, {}))
