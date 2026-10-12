# =============================================================================
# Centralized log shipping (check sheet feature 6, FULL)
# =============================================================================
# AWS's aws_cloudwatch_log_group.locker with var.log_retention_days becomes an
# OCI Logging log group plus a log. Retention and access control are
# group-level on both clouds, so the shape survives.
#
# WHAT CHANGED WITH THE COMPUTE TIER. On AWS the log group receives the
# CloudWatch-agent stream from the locker EC2 fleet, and IAM feature 8 exists
# purely to scope the instance role's write access to it. Under this port's
# shape (see database.tf's header) there is no VM: the card-vault pod writes to
# stdout and the platform's vector/loki pipeline collects it, exactly as for
# every other application on the cluster. So no workload needs a log-write
# grant from this module, and identity.tf emits none - the AWS `locker_logs`
# policy has no counterpart, by design rather than by omission.
#
# What remains worth centralising here is the DATABASE's engine log, which on
# AWS came through the nested database module's
# enabled_cloudwatch_logs_exports. Service "postgresql", category
# "postgresql_database_logs".
#
# UNVERIFIED, inherited from oci/modules/database.md open question 9.6: OCI
# describes the category as capturing "database queries and parameters"; AWS's
# postgresql export is the full server log including connection, error and
# autovacuum lines. If the content differs, vector/loki parsing rules change.
# Diff a sample against a live /aws/rds/cluster/.../postgresql stream before
# relying on existing alerting.

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

  # AWS's log_retention_days, same units, same meaning.
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
