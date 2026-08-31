# ============================================================================
# Memorystore for Valkey (GCP equivalent of AWS ElastiCache with
# engine="valkey"/cluster_mode="enabled") - genuinely different product and
# API from composition/memorystore (classic Memorystore for Redis,
# google_redis_instance). This wraps google_memorystore_instance via the
# SAME registry module already vendored elsewhere in this repo
# (terraform-google-modules/memorystore/google v16.1.1), just its other
# submodule (//modules/valkey).
#
# Networking is structurally different too: classic Memorystore-for-Redis
# connects over Private Service Access (a VPC peering, see
# composition/vpc-network's private_service_access_prefix_length). This
# product requires Private Service Connect instead - a
# google_network_connectivity_service_connection_policy authorizing the
# gcp-memorystore service class on a DEDICATED subnet, which the submodule
# creates for us from `subnet_names`. That subnet must already exist and be
# unused by anything else - PSC reserves addresses out of it directly.
#
# Usage:
#   module "memorystore_valkey" {
#     source = "../../modules/composition/memorystore-valkey"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     region       = "asia-south1"
#     network      = module.vpc_network.network_name  # bare name
#     subnet_names = ["hyperswitch-dev-memorystore"]   # bare name(s)
#
#     depends_on = [module.vpc_network]
#   }
# ============================================================================

module "valkey_cluster" {
  source  = "terraform-google-modules/memorystore/google//modules/valkey"
  version = "16.1.1"

  project_id  = var.project_id
  instance_id = local.instance_id
  location    = var.region

  network         = var.network
  network_project = var.network_project

  service_connection_policies = {
    "${local.instance_id}-scp" = {
      subnet_names = var.subnet_names
    }
  }

  mode           = var.mode
  shard_count    = var.shard_count
  replica_count  = var.replica_count
  node_type      = var.node_type
  engine_version = var.engine_version

  authorization_mode      = var.authorization_mode
  transit_encryption_mode = var.transit_encryption_mode

  deletion_protection_enabled = var.deletion_protection_enabled

  enable_apis = true

  labels = local.common_labels
}
