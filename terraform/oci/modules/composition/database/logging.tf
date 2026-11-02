# Engine log export to OCI Logging. Service "postgresql", category
# "postgresql_database_logs".
#
# UNVERIFIED: OCI describes the category as capturing "database queries and
# parameters"; the full server log includes connection, error and autovacuum
# lines. If the content differs, the vector/loki parsing rules change - diff a
# sample against a live stream before relying on existing alerting.

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
