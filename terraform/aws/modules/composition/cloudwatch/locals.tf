locals {
  name_prefix = "${var.environment}-${var.project_name}"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "CloudWatch"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  # Transform classified_metric_alarms into flat metric_alarms format
  # This creates separate alarms for each threshold/severity combination
  classified_alarms_flat = merge([
    for alarm_key, alarm_config in var.classified_metric_alarms : {
      for severity_key, severity_config in alarm_config.severity_config : "${alarm_key}-${severity_key}" => {
        alarm_name          = "${local.name_prefix}-${alarm_key}-${severity_key}"
        alarm_description   = severity_config.description
        comparison_operator = severity_config.comparison_operator
        evaluation_periods  = alarm_config.thresholds[severity_key].evaluation_periods
        metric_name         = alarm_config.metric_name
        namespace           = alarm_config.namespace
        period              = alarm_config.period
        statistic           = alarm_config.statistic
        threshold           = alarm_config.thresholds[severity_key].threshold
        dimensions          = alarm_config.dimensions
        treat_missing_data  = alarm_config.thresholds[severity_key].treat_missing_data
        datapoints_to_alarm = alarm_config.thresholds[severity_key].datapoints_to_alarm
        alarm_actions       = severity_config.alarm_actions
        ok_actions          = severity_config.ok_actions
        # Add classification tag for organization
        additional_tags = {
          Classification = alarm_config.classification
          Severity       = severity_config.severity
        }
      }
    }
  ]...)

  # Group alarms by classification for output organization
  alarms_by_classification = {
    for key, alarm in local.classified_alarms_flat :
    alarm.additional_tags.Classification => key...
  }
}
