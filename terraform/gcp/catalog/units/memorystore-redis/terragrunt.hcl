# Memorystore for Redis, the CLASSIC product (google_redis_instance), STANDARD_HA
# by default: a primary plus a synchronous standby in another zone. This is the
# Redis-engine sibling of the memorystore-valkey unit, for environments that
# want Redis instead of Valkey.
#
# It deliberately is NOT Memorystore for Redis Cluster. That product blocks
# CLUSTER FAILOVER (NOPERM) and has no failover command, so a failover cannot
# be exercised on it; the classic product has one:
#   gcloud redis instances failover <instance> --region <region>
#     [--data-protection-mode limited-data-loss|force-data-loss]
# The application talks to it as a plain, NON-cluster Redis: one host:port, so
# the client must run with cluster_enabled = false.
#
# Connectivity is Private Service Access, the same peering AlloyDB uses, so it
# needs the vpc-network unit's network and PSA range - not the dedicated
# `memorystore` PSC subnet that valkey uses. The two units therefore no longer
# contend for a subnet, but they are still meant to be exclusive per
# environment (one cache engine per stack): redis_enabled defaults to false and
# valkey_enabled to true, so a stack opts in with redis_enabled = true AND
# valkey_enabled = false.
#
# auth and transit encryption are left off, matching the application's lack of
# Redis AUTH/TLS support.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

exclude {
  if      = !try(values.redis_enabled, false)
  actions = ["all"]
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_id                        = "projects/mock/global/networks/mock-vpc"
    private_service_access_range_name = "mock-psa-range"
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

  authorized_network = dependency.vpc.outputs.network_id
  reserved_ip_range  = dependency.vpc.outputs.private_service_access_range_name

  # STANDARD_HA is the analogue of AWS multi_az_enabled = true: a primary plus
  # a synchronous standby (the replica) in a different zone, with automatic
  # failover AND `gcloud redis instances failover`. The standby IS the replica
  # a failover promotes - BASIC has none, so it cannot fail over at all (a node
  # failure there is downtime). Hence STANDARD_HA stays the default.
  tier = try(values.redis.tier, "STANDARD_HA")

  # Classic Memorystore for Redis has no shards: it scales by instance size, and
  # the capacity tier (M1 1-4 GiB, M2 5-10, M3 11-35) is what sets network
  # throughput - within a tier a bigger instance is not faster. Redis is
  # single-threaded, and a single shared-core-nano Valkey shard was pinned
  # during the 1000 TPS ramp in earlier load tests, so the default starts at the
  # first size of the M3 tier (16 GiB) rather than at the minimum. Small or
  # throwaway environments can set redis.memory_size_gb lower.
  memory_size_gb = try(values.redis.memory_size_gb, 16)

  # Pinned rather than inherited from the module default so it cannot drift.
  redis_version = try(values.redis.redis_version, "REDIS_7_2")

  # Readable replicas on top of the HA standby (0 = none). NOT the old Redis
  # Cluster `replica_count` per shard: a stack that still sets
  # redis.replica_count / shard_count / node_type has those silently ignored.
  read_replica_count = try(values.redis.read_replica_count, 0)

  # Pin the primary and standby to specific zones, or leave unset to let Google
  # choose. Set both or neither.
  location_id             = try(values.redis.location_id, null)
  alternative_location_id = try(values.redis.alternative_location_id, null)

  auth_enabled            = false
  transit_encryption_mode = "DISABLED"

  # In-instance RDB snapshots, so data survives a node restart.
  persistence_config = {
    persistence_mode    = "RDB"
    rdb_snapshot_period = "TWENTY_FOUR_HOURS"
  }

  # Analogue of AWS maintenance_window = "mon:04:00-mon:05:00". Left unset,
  # Google picks the window - exactly the kind of thing that should not differ
  # silently between clouds.
  maintenance_policy = {
    day = "MONDAY"
    start_time = {
      hours   = 4
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }

  # redis_configs is deliberately unset: Memorystore's defaults already agree
  # with the stock ElastiCache group on the parameter that matters
  # (maxmemory-policy = volatile-lru). The knob is plumbed if a custom group
  # ever needs porting.

  labels = merge({
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "cache"
    engine      = "redis"
    managed_by  = "terraform"
  }, try(values.common_labels, {}))
}, try(values.cfg, {}))
