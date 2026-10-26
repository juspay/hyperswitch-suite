# Memorystore for Valkey - a different product and API from
# composition/memorystore (classic Memorystore for Redis).
#
# Connectivity is over Private Service Connect, not the Private Service Access
# peering the classic product uses: the submodule creates a service connection
# policy authorizing the gcp-memorystore service class on a dedicated subnet
# from `subnet_names`. That subnet must already exist and be otherwise unused,
# since PSC reserves addresses directly out of it.

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

  # Forwarded explicitly (it is also upstream's default) so the live layer can
  # see and pin it. Immutable after creation.
  zone_distribution_config_mode = var.zone_distribution_config_mode
  zone_distribution_config_zone = var.zone_distribution_config_zone

  # Engine parameters, inline rather than a separate parameter-group resource.
  engine_configs = var.engine_configs

  # Durability, split in two: persistence_config is the in-instance RDB/AOF
  # behaviour, automated_backup_config the scheduled off-instance backup.
  persistence_config      = var.persistence_config
  automated_backup_config = var.automated_backup_config

  # Maintenance window and version upgrade policy.
  weekly_maintenance_window = var.weekly_maintenance_window
  maintenance_version       = var.maintenance_version

  # Cross-region replication.
  instance_role      = var.instance_role
  primary_instance   = var.primary_instance
  secondary_instance = var.secondary_instance

  # Create-time restore sources.
  managed_backup_source = var.managed_backup_source
  gcs_source            = var.gcs_source

  authorization_mode      = var.authorization_mode
  transit_encryption_mode = var.transit_encryption_mode

  deletion_protection_enabled = var.deletion_protection_enabled

  enable_apis = true

  labels = local.common_labels
}
