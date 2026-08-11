# ============================================================================
# Locker's own Cloud SQL database
# ============================================================================
# Called by relative path rather than a pinned git ref (the AWS module pins
# git::...?ref=database-v0.1.6): there is no released tag for this tree yet.
# Switch to a versioned source once composition/cloud-sql is tagged.
module "database" {
  count = var.create_locker_database ? 1 : 0

  source = "../cloud-sql"

  project_id   = var.project_id
  environment  = var.environment
  project_name = var.project_name
  region       = var.region
  network_id   = var.network_id

  instance_name = coalesce(var.database_config.instance_name, "${local.name_prefix}-db")

  database_version    = var.database_config.database_version
  tier                = var.database_config.tier
  availability_type   = var.database_config.availability_type
  disk_size           = var.database_config.disk_size
  deletion_protection = var.database_config.deletion_protection

  database_name   = var.database_config.database_name
  master_username = var.database_config.master_username
  master_password = var.database_config.master_password

  encryption_key_name = coalesce(var.database_config.encryption_key_name, module.kms.keys["locker"])

  labels = local.common_labels
}
