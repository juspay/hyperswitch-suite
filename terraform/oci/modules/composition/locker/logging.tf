# Centralized log shipping. With no VM tier, the card-vault pod writes to stdout
# and vector/loki collects it, so no workload needs a log-write grant. What is
# centralised here is the DATABASE's engine log. Service "postgresql", category
# "postgresql_database_logs".
#
# UNVERIFIED (open question 9.6): OCI describes the category as capturing
# "database queries and parameters"; AWS's postgresql export is the full server
# log. If the content differs, vector/loki parsing rules change - diff a sample
# against a live stream before relying on existing alerting.

resource "oci_logging_log_group" "locker" {
  count = local.enable_db_logs ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-logs"
  description    = "Card vault logs for ${local.name_prefix}"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_logging_log" "database" {
  count = local.enable_db_logs ? 1 : 0

  log_group_id = oci_logging_log_group.locker[0].id
  display_name = "${local.db_display_name}-postgresql"
  log_type     = "SERVICE"
  is_enabled   = true

  retention_duration = var.log_retention_days

  configuration {
    compartment_id = var.compartment_id

    source {
      service     = "postgresql"
      category    = "postgresql_database_logs"
      resource    = oci_psql_db_system.locker[0].id
      source_type = "OCISERVICE"
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
