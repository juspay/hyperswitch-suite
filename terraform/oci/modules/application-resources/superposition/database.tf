# =============================================================================
# Dedicated database (check sheet feature 6, SUBSTITUTE)
# =============================================================================
# Nested exactly the way the AWS module nests `composition/database`:
# `count = var.create_database`, inputs forwarded, a subset of outputs
# re-exported. Nesting rather than depending on the shared phase-1 `database`
# unit is not a new decision - it is what AWS already does, and what GCP's
# AlloyDB port already copied.
#
# ONE CONSEQUENCE WORTH STATING: because this database is nested rather than
# depended-on, it provisions in stack phase 3 alongside the app, not in phase 1
# with the shared database. Identical to AWS today; not a phasing change.
#
# The parity analysis for everything inside this call lives in
# docs/multi-cloud-parity/oci/modules/database.md and data-tier-strategy.md and
# is deliberately not restated here. The one superposition-specific point that
# is NOT visible from those documents: a reviewer auditing this module's
# identity contribution will see nothing about the database at all, and that is
# correct. OCI Database with PostgreSQL has no IAM-principal-to-database-user
# authentication path (database.md section 4.14, verdict NONE), so database
# access is a network/TLS/credential concern, not an IAM-statement one. The
# database adds ZERO statements to `policy_statements`.

module "database" {
  count = var.create_database ? 1 : 0

  source = "../../composition/database"

  compartment_id = var.compartment_id
  environment    = var.environment
  project_name   = var.project_name
  region         = var.region

  display_name = coalesce(var.database_config.display_name, "${local.name_prefix}-superposition")

  # Network. There is no subnet-group concept on OCI: the db system takes one
  # subnet OCID directly, which is why AWS's `create_db_subnet_group` and its
  # subnet-list companion have nothing to map onto.
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

  # No password is passed and none should be. OCI has no
  # manage_master_user_password equivalent, so the composition module generates
  # one and writes it to Vault when `vault_secret.create` is set.
  admin_username = var.database_config.admin_username
  vault_secret   = var.database_config.vault_secret

  # Two numbers where AWS had one. On AWS `backup_retention_period` is
  # simultaneously the scheduled-backup retention AND the PITR window; on OCI
  # they are independent policies, and setting only the first ships a database
  # with no point-in-time recovery at all.
  backup_kind           = var.database_config.backup_kind
  backup_start_hour     = var.database_config.backup_start_hour
  backup_retention_days = var.database_config.backup_retention_days
  backup_copy_regions   = var.database_config.backup_copy_regions
  pitr_restore_days     = var.database_config.pitr_restore_days

  # Cross-region DR. Aurora Global Database has no counterpart object; this is
  # Replication with Warm Standby - two independent db systems in a WAL
  # relationship, 300 s RPO floor, manual failover only, and PITR forfeited
  # while it is on. Off by default, and that default is a decision.
  enable_warm_standby  = var.database_config.enable_warm_standby
  primary_db_system_id = var.database_config.primary_db_system_id
  is_rpo_enforced      = var.database_config.is_rpo_enforced
  rpo_in_seconds       = var.database_config.rpo_in_seconds

  query_insights_enabled = var.database_config.query_insights_enabled
  enable_service_logs    = var.database_config.enable_service_logs
  log_retention_duration = var.database_config.log_retention_duration

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
