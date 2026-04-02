# CloudWatch Module

Terraform module for creating AWS CloudWatch resources including metric alarms, log groups, dashboards, and anomaly detection.

## Usage

### Basic Metric Alarm

```hcl
module "cloudwatch" {
  source = "./terraform/aws/modules/composition/cloudwatch"

  environment  = "dev"
  project_name = "hyperswitch"

  metric_alarms = {
    high-cpu = {
      alarm_name          = "high-cpu-utilization"
      alarm_description   = "Alert when CPU exceeds 80%"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      dimensions          = { InstanceId = "i-1234567890" }
      alarm_actions       = [aws_sns_topic.alerts.arn]
    }
  }
}
```

### Metric Anomaly Detection

```hcl
module "cloudwatch" {
  source = "./terraform/aws/modules/composition/cloudwatch"

  environment  = "dev"
  project_name = "hyperswitch"

  metric_anomaly_alarms = {
    rds-connection-anomaly = {
      metric_name   = "DatabaseConnections"
      namespace     = "AWS/RDS"
      statistic     = "Average"
      dimensions    = { DBClusterIdentifier = "my-cluster" }
      standard_deviations = 2
      alarm_actions = [aws_sns_topic.alerts.arn]
    }
  }
}
```

### Log Groups

```hcl
module "cloudwatch" {
  source = "./terraform/aws/modules/composition/cloudwatch"

  environment  = "dev"
  project_name = "hyperswitch"

  log_groups = {
    app-logs = {
      name              = "/hyperswitch/app"
      retention_in_days = 14
    }
    audit-logs = {
      name              = "/hyperswitch/audit"
      retention_in_days = 30
    }
  }
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| environment | Environment name | `string` | n/a |
| project_name | Project name for resource naming | `string` | `"hyperswitch"` |
| region | AWS region | `string` | `null` |
| tags | Common tags for all resources | `map(string)` | `{}` |
| metric_alarms | Map of CloudWatch metric alarms | `map(object)` | `{}` |
| metric_anomaly_alarms | Map of metric anomaly detection alarms | `map(object)` | `{}` |
| composite_alarms | Map of composite alarms with metric math | `map(object)` | `{}` |
| log_groups | Map of CloudWatch log groups | `map(object)` | `{}` |
| log_resource_policies | Map of log group resource policies | `map(object)` | `{}` |
| dashboards | Map of CloudWatch dashboards | `map(object)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| metric_alarm_arns | Map of metric alarm keys to ARNs |
| metric_alarm_names | Map of metric alarm keys to names |
| metric_anomaly_alarm_arns | Map of metric anomaly alarm keys to ARNs |
| metric_anomaly_alarm_names | Map of metric anomaly alarm keys to names |
| composite_alarm_arns | Map of composite alarm keys to ARNs |
| log_group_names | Map of log group keys to names |
| log_group_arns | Map of log group keys to ARNs |
| dashboard_urls | Map of dashboard keys to URLs |
| region | AWS region |
