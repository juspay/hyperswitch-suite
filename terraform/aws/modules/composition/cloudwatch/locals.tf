locals {
  name_prefix = var.region != null && var.region != "" ? "${var.environment}-${var.region}-${var.project_name}" : "${var.environment}-${var.project_name}"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "CloudWatch"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  resolve_dims = {
    for alarm_key, alarm_config in var.classified_metric_alarms :
    alarm_key => length(alarm_config.dimensions) > 0 ? alarm_config.dimensions : (
      alarm_config.dimension_key != "" ? lookup(var.dimension_map, alarm_config.dimension_key, {}) : {}
    )
  }

  resolve_anomaly_dims = {
    for alarm_key, alarm_config in var.classified_anomaly_alarms :
    alarm_key => length(alarm_config.dimensions) > 0 ? alarm_config.dimensions : (
      alarm_config.dimension_key != "" ? lookup(var.dimension_map, alarm_config.dimension_key, {}) : {}
    )
  }

  classified_alarms_flat = merge([
    for alarm_key, alarm_config in var.classified_metric_alarms : {
      for sev_key, sev_config in alarm_config.severities : "${alarm_key}-${sev_key}" => {
        alarm_name          = "${sev_key}-${local.name_prefix}-${alarm_key}"
        alarm_description   = sev_config.description
        comparison_operator = sev_config.comparison_operator
        evaluation_periods  = sev_config.evaluation_periods
        metric_name         = alarm_config.metric_name
        namespace           = alarm_config.namespace
        period              = alarm_config.period
        statistic           = alarm_config.statistic
        threshold           = sev_config.threshold
        dimensions          = local.resolve_dims[alarm_key]
        treat_missing_data  = sev_config.treat_missing_data
        datapoints_to_alarm = sev_config.datapoints_to_alarm
        skip_ok_action      = sev_config.skip_ok_action
        additional_tags = {
          Classification = alarm_config.classification
          Severity       = sev_key
        }
      }
    }
  ]...)

  classified_anomaly_alarms_flat = merge([
    for alarm_key, alarm_config in var.classified_anomaly_alarms : {
      for sev_key, sev_config in alarm_config.severities : "${alarm_key}-${sev_key}" => {
        alarm_name          = "${sev_key}-${local.name_prefix}-${alarm_key}"
        alarm_description   = sev_config.description
        comparison_operator = sev_config.comparison_operator
        evaluation_periods  = sev_config.evaluation_periods
        metric_name         = alarm_config.metric_name
        namespace           = alarm_config.namespace
        period              = alarm_config.period
        statistic           = alarm_config.statistic
        dimensions          = local.resolve_anomaly_dims[alarm_key]
        treat_missing_data  = sev_config.treat_missing_data
        standard_deviations = sev_config.standard_deviations
        skip_ok_action      = sev_config.skip_ok_action
        additional_tags = {
          Classification = alarm_config.classification
          Severity       = sev_key
        }
      }
    }
  ]...)

  alarms_by_classification = {
    for key, alarm in local.classified_alarms_flat :
    alarm.additional_tags.Classification => key...
  }

  anomaly_alarms_by_classification = {
    for key, alarm in local.classified_anomaly_alarms_flat :
    alarm.additional_tags.Classification => key...
  }
}
