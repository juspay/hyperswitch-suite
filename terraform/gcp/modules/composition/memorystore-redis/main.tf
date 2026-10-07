# Memorystore for Redis - the CLASSIC product (google_redis_instance, via the
# registry module's root module), STANDARD_HA by default: one primary plus a
# synchronous standby in another zone, with automatic failover AND a
# customer-triggerable manual failover:
#
#   gcloud redis instances failover <instance> --region <region> \
#     [--data-protection-mode limited-data-loss|force-data-loss]
#
# This replaces the earlier Memorystore for Redis CLUSTER implementation of this
# module (google_redis_cluster). That product blocks CLUSTER FAILOVER ("NOPERM
# this user has no permissions to run the 'cluster|failover' command" - listed in
# its "Supported and blocked commands" page) and has no failover command in
# `gcloud redis clusters`, so a failover cannot be exercised on it. The classic
# product can, which is what the zonal-failover resilience tests need.
#
# Connectivity is Private Service Access (the same peering AlloyDB uses), NOT
# the Private Service Connect + dedicated subnet that Redis Cluster / Valkey
# need, so no service connection policy and no `memorystore` subnet is involved
# here. The application talks to it as a plain, non-cluster Redis (a single
# host:port, cluster_enabled = false on the client).

module "redis" {
  source  = "terraform-google-modules/memorystore/google"
  version = "16.1.1"

  project_id   = var.project_id
  region       = var.region
  name         = local.instance_id
  display_name = local.instance_id

  tier           = var.tier
  memory_size_gb = var.memory_size_gb
  redis_version  = var.redis_version

  # Placement. Leave both null to let Google choose; set both to pin the
  # primary and the standby to specific, different zones.
  location_id             = var.location_id
  alternative_location_id = var.alternative_location_id

  # Replicas. STANDARD_HA always has exactly one standby; `read_replica_count`
  # adds readable replicas on top (the provider then wants replica_count = the
  # number of read replicas, 1-5, and READ_REPLICAS_ENABLED). Without read
  # replicas the only valid replica_count for STANDARD_HA is 1, and for BASIC 0.
  read_replicas_mode = local.read_replicas_enabled ? "READ_REPLICAS_ENABLED" : "READ_REPLICAS_DISABLED"
  replica_count      = local.replica_count
  secondary_ip_range = var.secondary_ip_range

  # Private Service Access. Both are pinned: the registry module's own defaults
  # are connect_mode = DIRECT_PEERING and transit_encryption_mode =
  # SERVER_AUTHENTICATION (TLS on), neither of which this stack wants.
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  authorized_network = var.authorized_network
  reserved_ip_range  = var.reserved_ip_range

  auth_enabled            = var.auth_enabled
  transit_encryption_mode = var.transit_encryption_mode

  redis_configs = var.redis_configs

  # In-instance RDB snapshots (null leaves persistence off).
  persistence_config = var.persistence_config

  maintenance_policy = var.maintenance_policy

  customer_managed_key = var.customer_managed_key

  enable_apis = true

  labels = local.common_labels
}
