# =============================================================================
# On-demand backup (check sheet feature 10, PARTIAL - section 4.8)
# =============================================================================
# The closest analogue of AWS's final_snapshot_identifier / skip_final_snapshot
# pair. There is no "take a snapshot on delete" behaviour on OCI; instead,
# management_policy.backup_policy.retention_days keeps automatic backups alive
# after the db system is deleted, and this resource creates a named manual
# backup that can be retained independently.
#
# It matters more here than on AWS, because there is no deletion_protection to
# fall back on (section 4.12 mitigation layer b).
#
# CAUTION: restore is unavailable while Replication with Warm Standby is
# enabled, on the primary AND the standby. A backup taken here is still valid,
# but recovering from it on a replicated pair requires breaking replication
# first - convert the standby to standalone, restore, re-establish. That order
# is a runbook step, not something Terraform sequences.

resource "oci_psql_backup" "on_demand" {
  count = var.on_demand_backup != null ? 1 : 0

  compartment_id = var.compartment_id
  db_system_id   = oci_psql_db_system.this.id

  display_name     = var.on_demand_backup.display_name
  description      = try(var.on_demand_backup.description, null)
  retention_period = try(var.on_demand_backup.retention_period, null)

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
