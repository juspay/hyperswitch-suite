# ============================================================================
# OCI Monitoring Alarms - equivalent of AWS aws_cloudwatch_metric_alarm.
# No verified registry module exists - raw oci provider resources.
# ============================================================================
resource "oci_monitoring_alarm" "this" {
  for_each = var.metric_alarms

  compartment_id               = var.compartment_id
  display_name                 = each.value.display_name
  metric_compartment_id        = coalesce(each.value.metric_compartment_id, var.compartment_id)
  namespace                    = each.value.namespace
  query                        = each.value.query
  severity                     = each.value.severity
  destinations                 = each.value.destinations
  pending_duration             = each.value.pending_duration
  is_enabled                   = each.value.is_enabled
  body                         = each.value.body
  repeat_notification_duration = each.value.repeat_notification_duration
  resource_group               = each.value.resource_group

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# OCI Logging - equivalent of AWS aws_cloudwatch_log_group /
# aws_cloudwatch_log_stream. No verified registry module exists.
# ============================================================================
resource "oci_logging_log_group" "this" {
  for_each = var.log_groups

  compartment_id = var.compartment_id
  display_name   = each.value

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_logging_log" "custom" {
  for_each = var.custom_logs

  display_name       = each.value.display_name
  log_group_id       = oci_logging_log_group.this[each.value.log_group_key].id
  log_type           = "CUSTOM"
  is_enabled         = true
  retention_duration = each.value.retention_duration

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
