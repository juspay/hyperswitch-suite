# =============================================================================
# Output contract
#
# Mapped from the AWS module's 17 outputs (check sheet section 5). Nine of them
# have nothing to emit, each for a reason recorded in main.tf rather than
# emitted as an empty map:
#
#   metric_alarm_arns / metric_alarm_names
#     feature 2 not carried forward (FULL but unused on AWS).
#   composite_alarm_arns / composite_alarm_names
#     feature 3 is SUBSTITUTE - no composite alarm resource exists.
#   metric_anomaly_alarm_arns / _names
#   classified_anomaly_alarm_arns / _names / anomaly_alarms_by_classification
#     features 5 & 6 are NONE - no resource, no output.
#   log_stream_arns
#     feature 9 - streams, if ever needed, are their own oci_logging_log
#     entries, so they appear in `log_ids` rather than as a sub-output.
#   dashboard_urls
#     feature 11 not carried forward.
# =============================================================================

output "classified_alarm_ocids" {
  description = "Map of \"<alarm>-<severity>\" to alarm OCID. Counterpart of AWS's classified_alarm_arns."
  value       = { for k, v in oci_monitoring_alarm.classified : k => v.id }

  # ---------------------------------------------------------------------------
  # Plan-time checks. Both are failure modes OCI has and AWS does not, so they
  # cannot be caught by reading the AWS config across.
  # ---------------------------------------------------------------------------
  precondition {
    condition     = length(local.alarms_missing_destinations) == 0
    error_message = "These alarms have no destination: ${join(", ", local.alarms_missing_destinations)}. `destinations` is REQUIRED and non-empty on oci_monitoring_alarm - unlike AWS, where an alarm with empty alarm_actions is legal and quietly notifies nobody. Set var.destinations[<severity>] or var.default_destinations to an ONS topic OCID from the `notifications` module."
  }

  precondition {
    condition     = length(local.alarms_with_out_of_range_pending_duration) == 0
    error_message = "These alarms derive a pending_duration longer than OCI's PT1H maximum: ${join(", ", local.alarms_with_out_of_range_pending_duration)}. evaluation_periods x period exceeds 60 minutes. This is NOT clamped automatically, because silently shortening an alarm's evaluation window changes what it means - set an explicit pending_duration on the severity, or reduce evaluation_periods."
  }
}

output "classified_alarm_names" {
  description = "Map of \"<alarm>-<severity>\" to alarm display name"
  value       = { for k, v in oci_monitoring_alarm.classified : k => v.display_name }
}

output "classified_alarm_queries" {
  description = "Map of \"<alarm>-<severity>\" to the rendered MQL query string. No AWS counterpart, and the single most useful output for review: `terraform validate` cannot check MQL grammar, so a human reading a sample of these is validation-ladder rung 5 for this module."
  value       = { for k, v in oci_monitoring_alarm.classified : k => v.query }
}

output "alarms_by_classification" {
  description = "Map of classification to the list of flattened alarm keys in it. The AWS module's grouping local, ported unchanged."
  value       = local.alarms_by_classification
}

output "log_group_ids" {
  description = "Map of log-group key to OCID. Counterpart of AWS's log_group_arns."
  value       = { for k, v in oci_logging_log_group.this : k => v.id }
}

output "log_group_names" {
  description = "Map of log-group key to display name"
  value       = { for k, v in oci_logging_log_group.this : k => v.display_name }
}

output "log_ids" {
  description = "Map of log key to OCID. Covers both CUSTOM logs (feature 9's log-stream counterpart) and SERVICE logs (feature 10's substitute for the log resource policy)."
  value       = { for k, v in oci_logging_log.this : k => v.id }
}

output "service_log_sources" {
  description = "Map of log key to the (service, resource, category) triple it is bound to, for the SERVICE-type logs. The auditable form of what AWS expressed as a log resource policy document."
  value = {
    for k, v in local.logs : k => v.source
    if v.log_type == "SERVICE" && v.source != null
  }
}

output "region" {
  description = "OCI region identifier, passed through"
  value       = var.region
}
