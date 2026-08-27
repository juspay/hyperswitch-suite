# ============================================================================
# Cloud SQL (GCP equivalent of composition/database)
# ============================================================================
# Regional-HA PostgreSQL instance with optional read replicas and CMEK. The
# AWS module's Aurora Global Cluster concept has no direct Cloud SQL
# equivalent; the closest match is a cross-region read replica, exposed here
# the same way (`read_replicas`, one of which may be `region`-different).
#
# Usage:
#   module "cloud_sql" {
#     source = "../../modules/composition/cloud-sql"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     region       = "europe-west1"
#     network_id   = module.vpc_network.network_id
#
#     depends_on = [module.vpc_network] # for Private Service Access
#   }
# ============================================================================

module "cloud_sql" {
  source  = "terraform-google-modules/sql-db/google//modules/postgresql"
  version = "28.1.0"

  project_id = var.project_id
  region     = var.region
  name       = local.instance_name

  database_version  = var.database_version
  tier              = var.tier
  edition           = var.edition
  availability_type = var.availability_type

  disk_size           = var.disk_size
  disk_type           = var.disk_type
  disk_autoresize     = var.disk_autoresize
  deletion_protection = var.deletion_protection

  ip_configuration = {
    ipv4_enabled                                  = false
    private_network                               = var.network_id
    enable_private_path_for_google_cloud_services = true
    ssl_mode                                      = "ENCRYPTED_ONLY"
    authorized_networks                           = []
  }

  database_flags = var.database_flags

  backup_configuration = {
    enabled                        = true
    start_time                     = var.backup_start_time
    point_in_time_recovery_enabled = var.enable_point_in_time_recovery
    transaction_log_retention_days = var.transaction_log_retention_days
    retained_backups               = var.retained_backups
    retention_unit                 = "COUNT"
  }

  db_name              = var.database_name
  user_name            = var.master_username
  user_password        = var.master_password
  random_instance_name = var.random_instance_name

  encryption_key_name = local.kms_key_name

  read_replicas = var.read_replicas

  user_labels = local.common_labels

  module_depends_on = var.module_depends_on
}
