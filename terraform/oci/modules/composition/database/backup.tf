# On-demand manual backup, retained independently of the db system's policy.
#
# CAUTION: restore is unavailable while Replication with Warm Standby is
# enabled on the primary AND the standby. Recovering from a backup on a
# replicated pair requires breaking replication first - convert the standby to
# standalone, restore, re-establish.

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
