# CloudWatch Metric Alarm Outputs
output "metric_alarm_arns" {
  description = "Map of metric alarm keys to ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.alarms : k => v.arn }
}

output "metric_alarm_names" {
  description = "Map of metric alarm keys to names"
  value       = { for k, v in aws_cloudwatch_metric_alarm.alarms : k => v.alarm_name }
}

# CloudWatch Composite Alarm Outputs
output "composite_alarm_arns" {
  description = "Map of composite alarm keys to ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.composite_alarms : k => v.arn }
}

output "composite_alarm_names" {
  description = "Map of composite alarm keys to names"
  value       = { for k, v in aws_cloudwatch_metric_alarm.composite_alarms : k => v.alarm_name }
}

# CloudWatch Log Group Outputs
output "log_group_names" {
  description = "Map of log group keys to log group names"
  value       = { for k, v in aws_cloudwatch_log_group.log_groups : k => v.name }
}

output "log_group_arns" {
  description = "Map of log group keys to ARNs"
  value       = { for k, v in aws_cloudwatch_log_group.log_groups : k => v.arn }
}

output "log_stream_arns" {
  description = "Map of log stream keys to ARNs"
  value       = { for k, v in aws_cloudwatch_log_stream.log_streams : k => v.arn }
}

# CloudWatch Dashboard Outputs
output "dashboard_urls" {
  description = "Map of dashboard keys to dashboard URLs"
  value = {
    for k, v in aws_cloudwatch_dashboard.dashboards :
    k => "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.region}#dashboards:name=${v.dashboard_name}"
  }
}

# CloudWatch Metric Anomaly Alarm Outputs
output "metric_anomaly_alarm_arns" {
  description = "Map of metric anomaly alarm keys to ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.metric_anomaly_alarms : k => v.arn }
}

output "metric_anomaly_alarm_names" {
  description = "Map of metric anomaly alarm keys to names"
  value       = { for k, v in aws_cloudwatch_metric_alarm.metric_anomaly_alarms : k => v.alarm_name }
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.region
}
