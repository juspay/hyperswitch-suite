# Grafana's own database
# Nested, not depended-on - it provisions in stack phase 3 alongside Grafana,
# not in phase 1 with the standalone `database` unit.
#
# CROSS-REGION DR IS NOT WIRED, and that is a recommendation, not a limitation:
# OCI PostgreSQL caps at EIGHT db systems per tenancy per region and every
# warm-standby relationship consumes a second slot. Grafana's database holds
# dashboards and alert rules - not payment data, not on the request path - so
# spending one of eight on it is the wrong default; a lost Grafana is recovered
# from a routine backup. `enable_warm_standby` and its siblings are therefore
# NOT exposed on `database_config`. Cross-region BACKUP COPY remains available
# via `database_config.backup_copy_regions`.

module "database" {
  count = var.create_database ? 1 : 0

  source = "../../composition/database"

  compartment_id = var.compartment_id
  environment    = var.environment
  project_name   = var.project_name
  region         = var.region

  display_name = coalesce(var.database_config.display_name, "${local.name_prefix}-grafana")

  subnet_id  = var.database_config.subnet_id
  vcn_id     = var.database_config.vcn_id
  create_nsg = var.database_config.create_nsg
  nsg_ids    = var.database_config.nsg_ids

  db_version       = var.database_config.db_version
  config_overrides = var.database_config.config_overrides

  shape                       = var.database_config.shape
  instance_ocpu_count         = var.database_config.instance_ocpu_count
  instance_memory_size_in_gbs = var.database_config.instance_memory_size_in_gbs
  instance_count              = var.database_config.instance_count

  storage_iops          = var.database_config.storage_iops
  is_regionally_durable = var.database_config.is_regionally_durable
  availability_domain   = var.database_config.availability_domain

  is_reader_endpoint_enabled = var.database_config.is_reader_endpoint_enabled

  admin_username = var.database_config.admin_username
  vault_secret   = var.database_config.vault_secret

  backup_kind           = var.database_config.backup_kind
  backup_start_hour     = var.database_config.backup_start_hour
  backup_retention_days = var.database_config.backup_retention_days
  backup_copy_regions   = var.database_config.backup_copy_regions
  pitr_restore_days     = var.database_config.pitr_restore_days

  query_insights_enabled = var.database_config.query_insights_enabled
  enable_service_logs    = var.database_config.enable_service_logs
  log_retention_duration = var.database_config.log_retention_duration

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
