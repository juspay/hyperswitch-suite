# =============================================================================
# Engine log export (check sheet feature 17, FULL)
# =============================================================================
# Same capability as AWS's enabled_cloudwatch_logs_exports = ["postgresql"],
# configured on separate resources instead of as an argument on the db system.
# Service "postgresql", category "postgresql_database_logs".
#
# UNVERIFIED (check sheet open question 9.6): OCI describes the category as
# capturing "database queries and parameters"; AWS's postgresql export is the
# full PostgreSQL server log, including connection, error and autovacuum lines.
# If the content differs, the vector/loki parsing rules change. Diff a sample
# against a live /aws/rds/cluster/.../postgresql stream before relying on
# existing alerting.

resource "oci_logging_log_group" "this" {
  count = var.enable_service_logs ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.display_name}-logs"
  description    = "Engine logs for ${local.display_name}"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_logging_log" "database" {
  count = var.enable_service_logs ? 1 : 0

  log_group_id = oci_logging_log_group.this[0].id
  display_name = "${local.display_name}-postgresql"
  log_type     = "SERVICE"
  is_enabled   = true

  retention_duration = var.log_retention_duration

  configuration {
    compartment_id = var.compartment_id

    source {
      service     = "postgresql"
      category    = "postgresql_database_logs"
      resource    = oci_psql_db_system.this.id
      source_type = "OCISERVICE"
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
