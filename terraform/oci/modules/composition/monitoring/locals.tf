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

  # ===========================================================================
  # THE MQL QUERY BUILDER - this module's one genuinely new piece of logic
  # ===========================================================================
  # AWS's alarm resource takes five separate typed fields (metric_name, namespace,
  # period, statistic, threshold) plus comparison_operator. OCI takes ONE string:
  #
  #   CpuUtilization[1m]{resourceId = "ocid1.instance..."}.mean() > 85
  #
  # The typed variable surface is preserved and rendered here, deliberately. The
  # alternative - making every caller hand-write MQL - would force a rewrite of
  # 95 alarm definitions per environment, and would move a class of error
  # (mistyped metric name, wrong statistic) from a Terraform type check to an
  # API-time failure.
  #
  # KNOWN LIMIT, recorded because it is what check sheet open question 5 asks
  # about: `terraform validate` checks HCL, not MQL grammar. A syntactically
  # invalid query passes validate and plan and fails at apply. The builder
  # constrains the shape of every query it produces, which is the mitigation;
  # query_override bypasses that and is the only place a malformed query can
  # originate from a well-typed input.
  # ===========================================================================

  # AWS statistic names -> MQL statistical functions. MQL's documented set is
  # mean/avg, sum, count, min, max, percentile, rate, first, last, increment,
  # absent. Anything not in this table passes through verbatim, so an MQL
  # function name can be given directly.
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

  # AWS comparison-operator names -> MQL operators. Anything not in this table
  # passes through, so ">" etc. can be given directly.
  #
  # NOTE the two anomaly operators are absent on purpose:
  # GreaterThanUpperThreshold and LessThanLowerThreshold only mean anything
  # alongside an ANOMALY_DETECTION_BAND expression, which does not exist here
  # (features 5 & 6, NONE). Translating them to a plain > or < would silently
  # turn an anomaly alarm into a static-threshold alarm wearing its name - the
  # exact failure mode the check sheet warns about. They are left untranslated so
  # they produce an obviously wrong query rather than a plausibly wrong one, and
  # classified_anomaly_alarms fails validation before anyone gets here.
  mql_operators = {
    "GreaterThanThreshold"          = ">"
    "GreaterThanOrEqualToThreshold" = ">="
    "LessThanThreshold"             = "<"
    "LessThanOrEqualToThreshold"    = "<="
    "EqualToThreshold"              = "=="
    "NotEqualToThreshold"           = "!="
  }

  # AWS's period (seconds) -> MQL's [interval] window.
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

  # Severity KEY -> OCI alarm severity enum. AWS has no severity field on the
  # alarm at all: severity lives in the alarm name and in which SNS topic the
  # alarm routes to. OCI makes it a required first-class enum, so the mapping
  # has to be stated somewhere - here, once, rather than in 95 alarm entries.
  severity_enum = {
    "sev1" = "CRITICAL"
    "sev2" = "ERROR"
    "sev3" = "WARNING"
    "sev4" = "INFO"
  }

  # Dimension resolution - ported verbatim from the AWS module's `resolve_dims`.
  resolve_dims = {
    for alarm_key, alarm_config in var.classified_metric_alarms :
    alarm_key => length(alarm_config.dimensions) > 0 ? alarm_config.dimensions : (
      alarm_config.dimension_key != "" ? lookup(var.dimension_map, alarm_config.dimension_key, {}) : {}
    )
  }

  # `{key = "value", other = "value"}`, or "" when there are no dimensions.
  # Keys are SORTED: an unstable rendering order would produce a different query
  # string on every plan and a perpetual diff.
  mql_dimension_clauses = {
    for alarm_key, dims in local.resolve_dims :
    alarm_key => length(dims) == 0 ? "" : format(
      "{%s}",
      join(", ", [for k in sort(keys(dims)) : "${k} = \"${dims[k]}\""])
    )
  }

  # ===========================================================================
  # Classified alarm flattening
  # ===========================================================================
  # One resource per (alarm, severity) pair. This is the AWS module's own
  # `classified_alarms_flat` local, structurally unchanged - which is not a
  # coincidence: routing is per-resource on both clouds, so the same flattening
  # is forced by the same constraint. Only the per-resource body changes, from
  # typed fields to a rendered query string.
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

        # AWS's evaluation_periods x period is a count of consecutive breaching
        # windows. OCI's pending_duration is one continuous ISO-8601 duration.
        # Equivalent in intent, derived here so callers keep writing
        # evaluation_periods.
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

        # AWS merges these onto the alarm as tags; kept for the same reason -
        # `alarms_by_classification` is built from them and is a real output.
        additional_tags = {
          classification = alarm_config.classification
          severity       = sev_key
        }
      }
    }
  ])...)

  # Ported unchanged from the AWS module: it operates on the flattened map's
  # keys, not on any AWS-specific resource attribute.
  alarms_by_classification = {
    for key, alarm in local.classified_alarms_flat :
    alarm.classification => key...
  }

  # ===========================================================================
  # Logging
  # ===========================================================================
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

      # Retention lives on the LOG, not the log group - the reverse of AWS.
      # Falls back to the parent group's default so the AWS mental model
      # ("retention is a property of the group") still produces the right answer.
      retention_duration = coalesce(
        cfg.retention_duration,
        try(local.log_groups[cfg.log_group_key].retention, 30),
      )

      freeform_tags = merge(local.freeform_tags, cfg.freeform_tags)
      defined_tags  = merge(var.defined_tags, cfg.defined_tags)
    }
  }

  # Alarms whose destinations list came out empty. `destinations` is REQUIRED and
  # must be non-empty on oci_monitoring_alarm, so this is a plan-time error, not
  # an alarm that quietly notifies nobody the way an AWS alarm with empty
  # alarm_actions does. Surfaced through a precondition in outputs.tf.
  alarms_missing_destinations = [
    for key, alarm in local.classified_alarms_flat : key
    if length(alarm.destinations) == 0
  ]

  # Derived pending_durations outside OCI's PT1M..PT1H window. Clamping silently
  # would change an alarm's meaning, so this is surfaced rather than fixed.
  alarms_with_out_of_range_pending_duration = [
    for key, alarm in local.classified_alarms_flat : key
    if alarm.pending_duration_minutes != null && alarm.pending_duration_minutes > 60
  ]
}
