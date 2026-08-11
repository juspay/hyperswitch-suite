<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_log_sinks"></a> [log\_sinks](#module\_log\_sinks) | terraform-google-modules/log-export/google | 11.1.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_logging_metric.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_metric) | resource |
| [google_monitoring_alert_policy.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_dashboard.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_dashboard) | resource |
| [google_monitoring_notification_channel.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_notification_channel) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alert_policies"></a> [alert\_policies](#input\_alert\_policies) | Map of alert policies to create, keyed by logical name. notification\_channel\_keys reference keys in var.notification\_channels | <pre>map(object({<br/>    combiner = string # AND, OR, AND_WITH_MATCHING_RESOURCE<br/>    conditions = list(object({<br/>      display_name       = string<br/>      filter             = string<br/>      comparison         = string # COMPARISON_GT, COMPARISON_LT, ...<br/>      threshold_value    = number<br/>      duration           = string<br/>      alignment_period   = optional(string, "60s")<br/>      per_series_aligner = optional(string, "ALIGN_MEAN")<br/>    }))<br/>    notification_channel_keys = optional(list(string), [])<br/>    documentation             = optional(string)<br/>    labels                    = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_dashboards"></a> [dashboards](#input\_dashboards) | Map of dashboard definitions (as native Terraform objects, JSON-encoded internally) keyed by logical name | `map(any)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_log_metrics"></a> [log\_metrics](#input\_log\_metrics) | Map of log-based metrics to create, keyed by logical name | <pre>map(object({<br/>    filter      = string<br/>    description = optional(string)<br/>    metric_kind = optional(string, "DELTA")<br/>    value_type  = optional(string, "INT64")<br/>    unit        = optional(string, "1")<br/>  }))</pre> | `{}` | no |
| <a name="input_log_sinks"></a> [log\_sinks](#input\_log\_sinks) | Map of project-level log sinks to create, keyed by logical name | <pre>map(object({<br/>    destination_uri = string # e.g. "storage.googleapis.com/<bucket>" or "pubsub.googleapis.com/projects/<p>/topics/<t>"<br/>    filter          = string<br/>  }))</pre> | `{}` | no |
| <a name="input_notification_channels"></a> [notification\_channels](#input\_notification\_channels) | Map of notification channels to create, keyed by logical name | <pre>map(object({<br/>    type        = string # e.g. "email", "pubsub", "slack", "pagerduty"<br/>    labels      = map(string)<br/>    description = optional(string)<br/>    enabled     = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where monitoring resources are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_alert_policy_ids"></a> [alert\_policy\_ids](#output\_alert\_policy\_ids) | Map of alert policy key to its resource ID |
| <a name="output_dashboard_ids"></a> [dashboard\_ids](#output\_dashboard\_ids) | Map of dashboard key to its resource ID |
| <a name="output_log_metric_ids"></a> [log\_metric\_ids](#output\_log\_metric\_ids) | Map of log-based metric key to its resource ID |
| <a name="output_log_sink_writer_identities"></a> [log\_sink\_writer\_identities](#output\_log\_sink\_writer\_identities) | Map of log sink key to its writer service-account identity, for granting it write access to the destination |
| <a name="output_notification_channel_ids"></a> [notification\_channel\_ids](#output\_notification\_channel\_ids) | Map of notification channel key to its resource ID |
<!-- END_TF_DOCS -->
