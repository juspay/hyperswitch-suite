# =============================================================================
# Grafana's own database (check sheet features 4, 5, 6)
# =============================================================================
# Nested, not depended-on - exactly as the AWS module nests `composition/database`
# and the GCP module nests `composition/alloydb`. The consequence: this database
# provisions in stack phase 3 alongside Grafana rather than in phase 1 with the
# standalone `database` unit. Identical to AWS today, so not a phasing change -
# but it does mean this module inherits every one of database.md section 8's
# gate items a SECOND time, for a second independently-provisioned db system.
#
# The 24-feature parity mapping is database.md's and is inherited wholesale
# rather than re-derived. Two of its findings change GRAFANA's own configuration
# and are therefore called out on `database_config` in variables.tf: TLS is
# mandatory (GF_DATABASE_SSL_MODE), and there is no per-app database.
#
# CROSS-REGION DR IS NOT WIRED, AND THAT IS A RECOMMENDATION THIS PORT MAKES
# RATHER THAN A LIMITATION IT HIT (check sheet section 4.5, SUBSTITUTE).
#
#   AWS exposes `database_create_global_cluster` plus six siblings, all
#   passed straight through, all UNSET in the one live unit reviewed. On OCI
#   there is no global-cluster object at all; the analogue is Replication with
#   Warm Standby - a WAL-streaming relationship between two independent db
#   systems, 300 s minimum enforceable RPO, manual-only failover, and mutually
#   exclusive with point-in-time restore while active.
#
#   The reason not to build it is specific to THIS consumer, not to the
#   technology: Grafana's database holds dashboards, users and alert-rule
#   definitions. Operationally inconvenient to lose; not payment data, and not
#   on the request path. OCI's PostgreSQL service caps at EIGHT db systems per
#   tenancy per region (database.md open question 9.8), and every warm-standby
#   relationship consumes a second slot in the DR region for one primary.
#   Spending one of eight on a dashboards database while the payments database
#   competes for the same budget is the wrong default. A lost Grafana is
#   recovered by re-provisioning against a routine backup.
#
#   So `enable_warm_standby`, `primary_db_system_id`, `is_rpo_enforced` and
#   `rpo_in_seconds` are NOT exposed on `database_config` - the "carrying dead
#   knobs" principle. Reintroducing them later is mechanical (they exist on the
#   composition module) but not free, and it competes for the same eight-per-
#   region ceiling at exactly the moment capacity is tightest. Oracle gate item
#   (check sheet section 8 item 3), NOT YET CONSULTED.
#
#   Cross-region BACKUP COPY remains available and is the cheap half of DR:
#   `database_config.backup_copy_regions`.

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
