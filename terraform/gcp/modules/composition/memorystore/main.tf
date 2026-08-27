# ============================================================================
# Memorystore for Redis (GCP equivalent of composition/elasticache)
# ============================================================================
# STANDARD_HA tier with optional read replicas, matching the AWS module's
# replication-group + optional global-replication-group shape. GCP has no
# direct Global Datastore equivalent; the closest analogue is a second
# Memorystore instance in another region kept in sync at the application
# layer, which is out of scope for this module (see README).
#
# Usage:
#   module "memorystore" {
#     source = "../../modules/composition/memorystore"
#
#     project_id          = "hyperswitch-dev"
#     environment         = "dev"
#     region              = "europe-west1"
#     authorized_network  = module.vpc_network.network_id
#
#     depends_on = [module.vpc_network] # for Private Service Access
#   }
# ============================================================================

module "memorystore" {
  source  = "terraform-google-modules/memorystore/google"
  version = "16.1.1"

  project_id = var.project_id
  region     = var.region
  name       = local.instance_name

  tier           = var.tier
  memory_size_gb = var.memory_size_gb
  redis_version  = var.redis_version
  connect_mode   = "PRIVATE_SERVICE_ACCESS"

  authorized_network = var.authorized_network
  read_replicas_mode = var.replica_count > 0 ? "READ_REPLICAS_ENABLED" : "READ_REPLICAS_DISABLED"
  replica_count      = var.replica_count

  auth_enabled            = var.auth_enabled
  transit_encryption_mode = var.transit_encryption_mode

  redis_configs = var.redis_configs

  persistence_config = var.persistence_mode != null ? {
    persistence_mode    = var.persistence_mode
    rdb_snapshot_period = var.rdb_snapshot_period
  } : null

  labels = local.common_labels
}
