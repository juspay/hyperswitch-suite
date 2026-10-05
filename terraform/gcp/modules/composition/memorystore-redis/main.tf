# Memorystore for Redis Cluster - the Redis-engine sibling of
# composition/memorystore-valkey, NOT the classic Memorystore for Redis
# product (composition/memorystore). Same new Memorystore platform as
# Valkey - Private Service Connect for discovery, not the Private Service
# Access peering the classic product uses - but a distinct GCP resource
# (google_redis_cluster, via the registry module's modules/redis-cluster)
# with its own variable surface, which is why this is a separate composition
# module rather than an engine switch on memorystore-valkey.

module "redis_cluster" {
  source  = "terraform-google-modules/memorystore/google//modules/redis-cluster"
  version = "16.1.1"

  project_id = var.project_id
  name       = local.instance_id
  region     = var.region

  network = ["projects/${local.network_project}/global/networks/${var.network}"]

  service_connection_policies = {
    "${local.instance_id}-scp" = {
      network_name    = var.network
      network_project = local.network_project
      subnet_names    = var.subnet_names
    }
  }

  shard_count   = var.shard_count
  replica_count = var.replica_count
  node_type     = var.node_type

  # Immutable after creation.
  zone_distribution_config_mode = var.zone_distribution_config_mode
  zone_distribution_config_zone = var.zone_distribution_config_zone

  # Engine parameters, inline rather than a separate parameter-group resource.
  redis_configs = var.redis_configs

  # In-instance RDB/AOF persistence. Unlike memorystore-valkey, this submodule
  # has no automated_backup_config / managed_backup_source / gcs_source - the
  # registry module simply doesn't expose scheduled off-instance backups or
  # create-time restore for this resource yet.
  persistence_config = var.persistence_config

  weekly_maintenance_window = var.weekly_maintenance_window

  # Cross-cluster replication (this resource's equivalent of
  # memorystore-valkey's instance_role/primary_instance/secondary_instance).
  cluster_role       = var.cluster_role
  primary_cluster    = var.primary_cluster
  secondary_clusters = var.secondary_clusters

  authorization_mode      = var.authorization_mode
  transit_encryption_mode = var.transit_encryption_mode

  deletion_protection_enabled = var.deletion_protection_enabled

  # CMEK - forwarded here because the submodule exposes it. memorystore-valkey
  # cannot forward the equivalent kms_key: the installed valkey submodule
  # version (16.1.1) doesn't expose it, even though the underlying resource
  # supports it.
  kms_key = var.kms_key

  enable_apis = true

  labels = local.common_labels
}
