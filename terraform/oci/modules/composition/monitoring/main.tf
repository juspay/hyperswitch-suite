# Monitoring and logging: OCI alarms, log groups and logs.

# Classified multi-severity metric alarms - one resource per (alarm, severity) pair.
resource "oci_monitoring_alarm" "classified" {
  for_each = local.classified_alarms_flat

  compartment_id = var.compartment_id
  display_name   = each.value.display_name

  # Compartment the evaluated metrics are emitted in - usually the same as compartment_id.
  metric_compartment_id            = local.metric_compartment_id
  metric_compartment_id_in_subtree = var.metric_compartment_id_in_subtree

  namespace      = each.value.namespace
  resource_group = each.value.resource_group

  # Rendered MQL string - see locals.tf. terraform validate cannot check MQL grammar.
  query = each.value.query

  # Pinned rather than the provider default: keeps every alarm's cadence stable.
  resolution = var.alarm_resolution

  # AWS evaluation_periods x period, expressed as one continuous window.
  pending_duration = each.value.pending_duration

  # Required enum with no AWS counterpart - see locals.severity_enum.
  severity = each.value.oci_severity

  body           = each.value.body
  message_format = var.alarm_message_format

  is_enabled = each.value.is_enabled

  # Per-severity routing: Oracle limits one destination per service, so the
  # per-severity split IS the routing mechanism.
  destinations = each.value.destinations

  # No AWS counterpart - CloudWatch notifies on state transition only.
  repeat_notification_duration = each.value.repeat_notification_duration

  freeform_tags = merge(local.freeform_tags, each.value.additional_tags)
  defined_tags  = var.defined_tags
}

# -----------------------------------------------------------------------------
# Anomaly-detection alarms: not implemented - MQL has no anomaly band or moving baseline.

# Composite / metric-math alarms: not implemented - MQL cannot combine multiple metric streams.

# Log groups.
# retention and kms live on the log, not the group; a group with no logs retains nothing.
resource "oci_logging_log_group" "this" {
  for_each = local.log_groups

  compartment_id = var.compartment_id
  display_name   = each.value.display_name
  description    = each.value.description

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags
}

# Logs - one resource, two log_types.
# log_type = "CUSTOM" maps log streams; log_type = "SERVICE" maps the log resource policy.
resource "oci_logging_log" "this" {
  for_each = local.logs

  log_group_id = oci_logging_log_group.this[each.value.log_group_key].id
  display_name = each.value.display_name
  log_type     = each.value.log_type
  is_enabled   = each.value.is_enabled

  # Days, 30-day increments to a 180-day ceiling.
  retention_duration = each.value.retention_duration

  dynamic "configuration" {
    for_each = each.value.source != null ? [each.value.source] : []

    content {
      compartment_id = var.compartment_id

      source {
        service     = configuration.value.service
        resource    = configuration.value.resource
        category    = configuration.value.category
        source_type = configuration.value.source_type
        parameters  = configuration.value.parameters
      }
    }
  }

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags
}

# Dashboards: not carried forward - unused on AWS; Grafana owns dashboards.

# Plain single-metric alarms (AWS metric_alarms): not carried forward - unused on AWS,
# and a single-severity classified alarm is the same thing.
