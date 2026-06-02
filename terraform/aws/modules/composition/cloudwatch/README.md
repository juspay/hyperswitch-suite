<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.32.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.32.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.dashboards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_log_group.log_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_resource_policy.log_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy) | resource |
| [aws_cloudwatch_log_stream.log_streams](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream) | resource |
| [aws_cloudwatch_metric_alarm.alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.classified_alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.classified_anomaly_alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.composite_alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.metric_anomaly_alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_classified_anomaly_alarms"></a> [classified\_anomaly\_alarms](#input\_classified\_anomaly\_alarms) | Map of classified anomaly detection alarms.<br/>Each alarm MUST define at least sev1.<br/>Set dimension\_key to a key in var.dimension\_map to resolve dimensions automatically.<br/>Or set dimensions explicitly to override. | <pre>map(object({<br/>    classification = string<br/>    metric_name    = string<br/>    namespace      = string<br/>    dimension_key  = optional(string, "")<br/>    dimensions     = optional(map(string), {})<br/>    period         = optional(number, 300)<br/>    statistic      = optional(string, "Average")<br/>    severities = map(object({<br/>      comparison_operator = optional(string, "GreaterThanUpperThreshold")<br/>      standard_deviations = optional(number, 2)<br/>      description         = string<br/>      evaluation_periods  = optional(number, 2)<br/>      treat_missing_data  = optional(string, "notBreaching")<br/>      skip_ok_action      = optional(bool, true)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_classified_metric_alarms"></a> [classified\_metric\_alarms](#input\_classified\_metric\_alarms) | Map of classified metric alarms with multi-severity support.<br/>Each alarm MUST define at least sev1.<br/>Set dimension\_key to a key in var.dimension\_map to resolve dimensions automatically.<br/>Or set dimensions explicitly to override. | <pre>map(object({<br/>    classification = string<br/>    metric_name    = string<br/>    namespace      = string<br/>    dimension_key  = optional(string, "")<br/>    dimensions     = optional(map(string), {})<br/>    period         = optional(number, 60)<br/>    statistic      = optional(string, "Average")<br/>    severities = map(object({<br/>      threshold           = number<br/>      comparison_operator = optional(string, "GreaterThanThreshold")<br/>      description         = string<br/>      evaluation_periods  = optional(number, 5)<br/>      datapoints_to_alarm = optional(number)<br/>      treat_missing_data  = optional(string, "notBreaching")<br/>      skip_ok_action      = optional(bool, true)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_composite_alarms"></a> [composite\_alarms](#input\_composite\_alarms) | Map of CloudWatch composite alarms with metric math | <pre>map(object({<br/>    alarm_name          = string<br/>    alarm_description   = optional(string, "")<br/>    comparison_operator = string<br/>    evaluation_periods  = number<br/>    threshold           = number<br/>    treat_missing_data  = optional(string, "missing")<br/>    metrics = list(object({<br/>      id          = string<br/>      expression  = optional(string)<br/>      label       = optional(string)<br/>      return_data = optional(bool, true)<br/>    }))<br/>    alarm_actions             = optional(list(string), [])<br/>    ok_actions                = optional(list(string), [])<br/>    insufficient_data_actions = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_dashboards"></a> [dashboards](#input\_dashboards) | Map of CloudWatch dashboards | <pre>map(object({<br/>    dashboard_name = string<br/>    dashboard_body = string<br/>  }))</pre> | `{}` | no |
| <a name="input_dimension_map"></a> [dimension\_map](#input\_dimension\_map) | Flat map of named dimension sets used by classified alarms.<br/>Each entry is a key (e.g. "rds", "kafka-broker-1") mapped to a CloudWatch dimension map.<br/>Alarms reference these by setting dimension\_key = "<key>".<br/>Build this in terragrunt at the top level of inputs so dependency.* refs are legal.<br/>Example:<br/>  dimension\_map = {<br/>    rds              = { DBClusterIdentifier = "my-cluster" }<br/>    elasticache      = { CacheClusterId      = "my-cache" }<br/>    kafka-broker-1   = { InstanceId          = "i-abc123" }<br/>  } | `map(map(string))` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/sandbox/prod) | `string` | n/a | yes |
| <a name="input_log_groups"></a> [log\_groups](#input\_log\_groups) | Map of CloudWatch log groups | <pre>map(object({<br/>    name              = string<br/>    retention_in_days = optional(number, 7)<br/>    kms_key_id        = optional(string)<br/>    log_streams       = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_log_resource_policies"></a> [log\_resource\_policies](#input\_log\_resource\_policies) | Map of CloudWatch log group resource policies | <pre>map(object({<br/>    policy_name     = string<br/>    policy_document = string<br/>  }))</pre> | `{}` | no |
| <a name="input_metric_alarms"></a> [metric\_alarms](#input\_metric\_alarms) | Map of CloudWatch metric alarms | <pre>map(object({<br/>    alarm_name                = string<br/>    alarm_description         = optional(string, "")<br/>    comparison_operator       = string<br/>    evaluation_periods        = number<br/>    metric_name               = string<br/>    namespace                 = string<br/>    period                    = number<br/>    statistic                 = string<br/>    threshold                 = number<br/>    dimensions                = optional(map(string), {})<br/>    alarm_actions             = optional(list(string), [])<br/>    ok_actions                = optional(list(string), [])<br/>    insufficient_data_actions = optional(list(string), [])<br/>    treat_missing_data        = optional(string, "missing")<br/>    datapoints_to_alarm       = optional(number)<br/>    threshold_metric_id       = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_metric_anomaly_alarms"></a> [metric\_anomaly\_alarms](#input\_metric\_anomaly\_alarms) | Map of CloudWatch metric anomaly detection alarms | <pre>map(object({<br/>    alarm_name                = optional(string)<br/>    alarm_description         = optional(string)<br/>    metric_name               = string<br/>    namespace                 = string<br/>    period                    = optional(number, 300)<br/>    statistic                 = optional(string, "Average")<br/>    dimensions                = optional(map(string), {})<br/>    evaluation_periods        = optional(number, 2)<br/>    comparison_operator       = optional(string, "GreaterThanUpperThreshold")<br/>    standard_deviations       = optional(number, 2)<br/>    alarm_actions             = optional(list(string), [])<br/>    ok_actions                = optional(list(string), [])<br/>    insufficient_data_actions = optional(list(string), [])<br/>    treat_missing_data        = optional(string, "missing")<br/>  }))</pre> | `{}` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region for resource naming | `string` | `null` | no |
| <a name="input_sns_topic_arns"></a> [sns\_topic\_arns](#input\_sns\_topic\_arns) | Map of severity to SNS topic ARNs (e.g. { sev1 = "arn:...", sev2 = "arn:..." }) | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alarms_by_classification"></a> [alarms\_by\_classification](#output\_alarms\_by\_classification) | Map of classifications to alarm keys for organization |
| <a name="output_anomaly_alarms_by_classification"></a> [anomaly\_alarms\_by\_classification](#output\_anomaly\_alarms\_by\_classification) | Map of classifications to anomaly alarm keys for organization |
| <a name="output_classified_alarm_arns"></a> [classified\_alarm\_arns](#output\_classified\_alarm\_arns) | Map of classified alarm keys to ARNs |
| <a name="output_classified_alarm_names"></a> [classified\_alarm\_names](#output\_classified\_alarm\_names) | Map of classified alarm keys to names |
| <a name="output_classified_anomaly_alarm_arns"></a> [classified\_anomaly\_alarm\_arns](#output\_classified\_anomaly\_alarm\_arns) | Map of classified anomaly alarm keys to ARNs |
| <a name="output_classified_anomaly_alarm_names"></a> [classified\_anomaly\_alarm\_names](#output\_classified\_anomaly\_alarm\_names) | Map of classified anomaly alarm keys to names |
| <a name="output_composite_alarm_arns"></a> [composite\_alarm\_arns](#output\_composite\_alarm\_arns) | Map of composite alarm keys to ARNs |
| <a name="output_composite_alarm_names"></a> [composite\_alarm\_names](#output\_composite\_alarm\_names) | Map of composite alarm keys to names |
| <a name="output_dashboard_urls"></a> [dashboard\_urls](#output\_dashboard\_urls) | Map of dashboard keys to dashboard URLs |
| <a name="output_log_group_arns"></a> [log\_group\_arns](#output\_log\_group\_arns) | Map of log group keys to ARNs |
| <a name="output_log_group_names"></a> [log\_group\_names](#output\_log\_group\_names) | Map of log group keys to log group names |
| <a name="output_log_stream_arns"></a> [log\_stream\_arns](#output\_log\_stream\_arns) | Map of log stream keys to ARNs |
| <a name="output_metric_alarm_arns"></a> [metric\_alarm\_arns](#output\_metric\_alarm\_arns) | Map of metric alarm keys to ARNs |
| <a name="output_metric_alarm_names"></a> [metric\_alarm\_names](#output\_metric\_alarm\_names) | Map of metric alarm keys to names |
| <a name="output_metric_anomaly_alarm_arns"></a> [metric\_anomaly\_alarm\_arns](#output\_metric\_anomaly\_alarm\_arns) | Map of metric anomaly alarm keys to ARNs |
| <a name="output_metric_anomaly_alarm_names"></a> [metric\_anomaly\_alarm\_names](#output\_metric\_anomaly\_alarm\_names) | Map of metric anomaly alarm keys to names |
| <a name="output_region"></a> [region](#output\_region) | AWS region |
<!-- END_TF_DOCS -->