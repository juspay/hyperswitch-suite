# Data sources
data "aws_region" "current" {}

# CloudWatch Metric Alarms
resource "aws_cloudwatch_metric_alarm" "alarms" {
  for_each = var.metric_alarms

  alarm_name          = each.value.alarm_name
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description

  # Dimensions
  dimensions = each.value.dimensions

  # Actions
  alarm_actions             = each.value.alarm_actions
  ok_actions                = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions

  # Additional configurations
  treat_missing_data  = each.value.treat_missing_data
  datapoints_to_alarm = each.value.datapoints_to_alarm
  threshold_metric_id = each.value.threshold_metric_id
  tags = merge(local.common_tags, {
    Name = each.value.alarm_name
  })
}

# CloudWatch Metric Alarms using Metric Queries
resource "aws_cloudwatch_metric_alarm" "composite_alarms" {
  for_each = var.composite_alarms

  alarm_name          = each.value.alarm_name
  alarm_description   = each.value.alarm_description
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  threshold           = each.value.threshold
  treat_missing_data  = each.value.treat_missing_data

  # Metric math configurations
  dynamic "metric_query" {
    for_each = each.value.metrics
    content {
      id          = metric_query.value.id
      expression  = metric_query.value.expression
      label       = metric_query.value.label
      return_data = metric_query.value.return_data
    }
  }

  # Actions
  alarm_actions             = each.value.alarm_actions
  ok_actions                = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions

  tags = merge(local.common_tags, {
    Name = each.value.alarm_name
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "log_groups" {
  for_each = var.log_groups

  name              = each.value.name
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_id

  tags = merge(local.common_tags, {
    Name = each.value.name
  })
}

# CloudWatch Log Streams
resource "aws_cloudwatch_log_stream" "log_streams" {
  for_each = merge([for log_group_key, log_group_val in var.log_groups : {
    for stream_key, stream_name in log_group_val.log_streams : "${log_group_key}-${stream_key}" => {
      log_group_name = aws_cloudwatch_log_group.log_groups[log_group_key].name
      name           = stream_name
    }
  }]...)

  name           = each.value.name
  log_group_name = each.value.log_group_name
}

# CloudWatch Log Group Policy
resource "aws_cloudwatch_log_resource_policy" "log_policies" {
  for_each = var.log_resource_policies

  policy_name     = each.value.policy_name
  policy_document = each.value.policy_document
}

# CloudWatch Dashboards
resource "aws_cloudwatch_dashboard" "dashboards" {
  for_each = var.dashboards

  dashboard_name = each.value.dashboard_name
  dashboard_body = each.value.dashboard_body
}


