# Per-environment instance log destination.
# Retention is a per-LOG property on OCI (30-180 days), and log_type = "CUSTOM"
# because these are application logs an agent ships in. Creating the destination does
# NOT make bytes appear - a logging agent configured in the custom image does that.

resource "oci_logging_log_group" "this" {
  count = var.enable_logging ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-logs"
  description    = "Instance logs for ${local.name_prefix}"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_logging_log" "this" {
  count = var.enable_logging ? 1 : 0

  log_group_id = oci_logging_log_group.this[0].id
  display_name = local.name_prefix
  log_type     = "CUSTOM"
  is_enabled   = true

  retention_duration = var.log_retention_days

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
