locals {
  name_prefix = var.region != null && var.region != "" ? "${var.environment}-${var.region}-${var.project_name}" : "${var.environment}-${var.project_name}"

  metric_compartment_id = var.metric_compartment_id != null ? var.metric_compartment_id : var.compartment_id

  freeform_tags = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "monitoring"
      "managed_by"  = "terraform"
    },
    var.freeform_tags
  )

  # MQL query builder - renders the typed AWS fields into one MQL string.
  # KNOWN LIMIT: `terraform validate` checks HCL, not MQL grammar; a malformed
  # query_override fails at apply, and cannot be caught earlier.

  # AWS statistic names -> MQL functions. Anything not listed passes through verbatim.
  mql_statistics = {
    "Average"     = "mean"
    "average"     = "mean"
    "Sum"         = "sum"
    "sum"         = "sum"
    "Minimum"     = "min"
    "minimum"     = "min"
    "Maximum"     = "max"
    "maximum"     = "max"
    "SampleCount" = "count"
  }

  # AWS comparison operators -> MQL operators. Anything not listed passes through.
  # The two anomaly operators are omitted on purpose so an anomaly alarm fails
  # loudly rather than silently becoming a static-threshold alarm.
  mql_operators = {
    "GreaterThanThreshold"          = ">"
    "GreaterThanOrEqualToThreshold" = ">="
    "LessThanThreshold"             = "<"
    "LessThanOrEqualToThreshold"    = "<="
    "EqualToThreshold"              = "=="
    "NotEqualToThreshold"           = "!="
  }

  # AWS period (seconds) -> MQL [interval].
  mql_intervals = {
    "60"    = "1m"
    "120"   = "2m"
    "180"   = "3m"
    "300"   = "5m"
    "600"   = "10m"
    "900"   = "15m"
    "1800"  = "30m"
    "3600"  = "1h"
    "10800" = "3h"
    "21600" = "6h"
    "43200" = "12h"
    "86400" = "24h"
  }

  # Severity key -> OCI alarm severity enum, stated here once rather than per alarm.
  severity_enum = {
    "sev1" = "CRITICAL"
    "sev2" = "ERROR"
    "sev3" = "WARNING"
    "sev4" = "INFO"
  }

  resolve_dims = {
    for alarm_key, alarm_config in var.classified_metric_alarms :
    alarm_key => length(alarm_config.dimensions) > 0 ? alarm_config.dimensions : (
      alarm_config.dimension_key != "" ? lookup(var.dimension_map, alarm_config.dimension_key, {}) : {}
    )
  }

  # `{key = "value"}` or "" when no dimensions. Keys are SORTED to avoid a perpetual diff.
  mql_dimension_clauses = {
    for alarm_key, dims in local.resolve_dims :
    alarm_key => length(dims) == 0 ? "" : format(
      "{%s}",
      join(", ", [for k in sort(keys(dims)) : "${k} = \"${dims[k]}\""])
    )
  }

  # Classified alarm flattening - one resource per (alarm, severity) pair.
  classified_alarms_flat = merge(concat([{}], [
    for alarm_key, alarm_config in var.classified_metric_alarms : {
      for sev_key, sev_config in alarm_config.severities : "${alarm_key}-${sev_key}" => {
        display_name   = "${sev_key}-${local.name_prefix}-${alarm_key}"
        body           = sev_config.description
        classification = alarm_config.classification
        severity_key   = sev_key
        namespace      = alarm_config.namespace
        resource_group = alarm_config.resource_group
        is_enabled     = sev_config.is_enabled

        oci_severity = (
          sev_config.oci_severity != null
          ? sev_config.oci_severity
          : lookup(local.severity_enum, sev_key, "WARNING")
        )

        # AWS evaluation_periods x period -> OCI pending_duration (one ISO-8601 duration).
        pending_duration = (
          sev_config.pending_duration != null
          ? sev_config.pending_duration
          : format("PT%dM", max(1, ceil(sev_config.evaluation_periods * alarm_config.period / 60)))
        )

        pending_duration_minutes = (
          sev_config.pending_duration != null
          ? null
          : max(1, ceil(sev_config.evaluation_periods * alarm_config.period / 60))
        )

        repeat_notification_duration = sev_config.repeat_notification_duration

        destinations = coalesce(
          sev_config.destinations,
          lookup(var.destinations, sev_key, null),
          var.default_destinations,
        )

        query = (
          alarm_config.query_override != null
          ? alarm_config.query_override
          : format(
            "%s[%s]%s%s.%s(%s) %s %s",
            alarm_config.metric_name,
            lookup(local.mql_intervals, tostring(alarm_config.period), "1m"),
            local.mql_dimension_clauses[alarm_key],
            (
              alarm_config.grouping == null || alarm_config.grouping == ""
              ? ""
              : (startswith(alarm_config.grouping, ".") ? alarm_config.grouping : ".${alarm_config.grouping}")
            ),
            lookup(local.mql_statistics, alarm_config.statistic, alarm_config.statistic),
            alarm_config.statistic_argument != null ? alarm_config.statistic_argument : "",
            lookup(local.mql_operators, sev_config.comparison_operator, sev_config.comparison_operator),
            sev_config.threshold,
          )
        )

        # Tag carriers for the real `alarms_by_classification` output.
        additional_tags = {
          classification = alarm_config.classification
          severity       = sev_key
        }
      }
    }
  ])...)

  alarms_by_classification = {
    for key, alarm in local.classified_alarms_flat :
    alarm.classification => key...
  }

  # Logging
  log_groups = {
    for key, cfg in var.log_groups : key => {
      display_name  = cfg.display_name != null ? cfg.display_name : "${local.name_prefix}-${key}"
      description   = cfg.description
      retention     = cfg.default_retention_duration
      freeform_tags = merge(local.freeform_tags, cfg.freeform_tags)
      defined_tags  = merge(var.defined_tags, cfg.defined_tags)
    }
  }

  logs = {
    for key, cfg in var.logs : key => {
      log_group_key = cfg.log_group_key
      display_name  = cfg.display_name != null ? cfg.display_name : "${local.name_prefix}-${key}"
      log_type      = cfg.log_type
      is_enabled    = cfg.is_enabled
      source        = cfg.source

      # Retention lives on the LOG, not the log group; falls back to the group's default.
      retention_duration = coalesce(
        cfg.retention_duration,
        try(local.log_groups[cfg.log_group_key].retention, 30),
      )

      freeform_tags = merge(local.freeform_tags, cfg.freeform_tags)
      defined_tags  = merge(var.defined_tags, cfg.defined_tags)
    }
  }

  # Alarms whose destinations came out empty - `destinations` is REQUIRED on
  # oci_monitoring_alarm, surfaced as a plan-time error in outputs.tf.
  alarms_missing_destinations = [
    for key, alarm in local.classified_alarms_flat : key
    if length(alarm.destinations) == 0
  ]

  # Derived pending_durations outside OCI's PT1H window - surfaced, not silently clamped.
  alarms_with_out_of_range_pending_duration = [
    for key, alarm in local.classified_alarms_flat : key
    if alarm.pending_duration_minutes != null && alarm.pending_duration_minutes > 60
  ]
}
