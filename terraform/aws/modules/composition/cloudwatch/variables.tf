variable "environment" {
  description = "Environment name (dev/sandbox/prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "(Optional) Region for resource naming"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "sns_topic_arns" {
  description = "Map of severity to SNS topic ARNs (e.g. { sev1 = \"arn:...\", sev2 = \"arn:...\" })"
  type        = map(string)
  default     = {}
}

variable "dimension_map" {
  description = <<-EOT
    Flat map of named dimension sets used by classified alarms.
    Each entry is a key (e.g. "rds", "kafka-broker-1") mapped to a CloudWatch dimension map.
    Alarms reference these by setting dimension_key = "<key>".
    Build this in terragrunt at the top level of inputs so dependency.* refs are legal.
    Example:
      dimension_map = {
        rds              = { DBClusterIdentifier = "my-cluster" }
        elasticache      = { CacheClusterId      = "my-cache" }
        kafka-broker-1   = { InstanceId          = "i-abc123" }
      }
  EOT
  type        = map(map(string))
  default     = {}
}

variable "metric_alarms" {
  description = "Map of CloudWatch metric alarms"
  type = map(object({
    alarm_name                = string
    alarm_description         = optional(string, "")
    comparison_operator       = string
    evaluation_periods        = number
    metric_name               = string
    namespace                 = string
    period                    = number
    statistic                 = string
    threshold                 = number
    dimensions                = optional(map(string), {})
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    treat_missing_data        = optional(string, "missing")
    datapoints_to_alarm       = optional(number)
    threshold_metric_id       = optional(string)
  }))
  default = {}
}

variable "composite_alarms" {
  description = "Map of CloudWatch composite alarms with metric math"
  type = map(object({
    alarm_name          = string
    alarm_description   = optional(string, "")
    comparison_operator = string
    evaluation_periods  = number
    threshold           = number
    treat_missing_data  = optional(string, "missing")
    metrics = list(object({
      id          = string
      expression  = optional(string)
      label       = optional(string)
      return_data = optional(bool, true)
    }))
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
  }))
  default = {}
}

variable "log_groups" {
  description = "Map of CloudWatch log groups"
  type = map(object({
    name              = string
    retention_in_days = optional(number, 7)
    kms_key_id        = optional(string)
    log_streams       = optional(map(string), {})
  }))
  default = {}
}

variable "log_resource_policies" {
  description = "Map of CloudWatch log group resource policies"
  type = map(object({
    policy_name     = string
    policy_document = string
  }))
  default = {}
}

variable "dashboards" {
  description = "Map of CloudWatch dashboards"
  type = map(object({
    dashboard_name = string
    dashboard_body = string
  }))
  default = {}
}

variable "metric_anomaly_alarms" {
  description = "Map of CloudWatch metric anomaly detection alarms"
  type = map(object({
    alarm_name                = optional(string)
    alarm_description         = optional(string)
    metric_name               = string
    namespace                 = string
    period                    = optional(number, 300)
    statistic                 = optional(string, "Average")
    dimensions                = optional(map(string), {})
    evaluation_periods        = optional(number, 2)
    comparison_operator       = optional(string, "GreaterThanUpperThreshold")
    standard_deviations       = optional(number, 2)
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    treat_missing_data        = optional(string, "missing")
  }))
  default = {}
}

variable "classified_metric_alarms" {
  description = <<-EOT
    Map of classified metric alarms with multi-severity support.
    Each alarm MUST define at least sev1.
    Set dimension_key to a key in var.dimension_map to resolve dimensions automatically.
    Or set dimensions explicitly to override.
  EOT
  type = map(object({
    classification = string
    metric_name    = string
    namespace      = string
    dimension_key  = optional(string, "")
    dimensions     = optional(map(string), {})
    period         = optional(number, 60)
    statistic      = optional(string, "Average")
    severities = map(object({
      threshold           = number
      comparison_operator = optional(string, "GreaterThanThreshold")
      description         = string
      evaluation_periods  = optional(number, 5)
      datapoints_to_alarm = optional(number)
      treat_missing_data  = optional(string, "notBreaching")
      skip_ok_action      = optional(bool, true)
    }))
  }))
  default = {}
  validation {
    condition     = alltrue([for k, v in var.classified_metric_alarms : contains(keys(v.severities), "sev1")])
    error_message = "Every classified_metric_alarm must define at least sev1 (critical severity)."
  }
}

variable "classified_anomaly_alarms" {
  description = <<-EOT
    Map of classified anomaly detection alarms.
    Each alarm MUST define at least sev1.
    Set dimension_key to a key in var.dimension_map to resolve dimensions automatically.
    Or set dimensions explicitly to override.
  EOT
  type = map(object({
    classification = string
    metric_name    = string
    namespace      = string
    dimension_key  = optional(string, "")
    dimensions     = optional(map(string), {})
    period         = optional(number, 300)
    statistic      = optional(string, "Average")
    severities = map(object({
      comparison_operator = optional(string, "GreaterThanUpperThreshold")
      standard_deviations = optional(number, 2)
      description         = string
      evaluation_periods  = optional(number, 2)
      treat_missing_data  = optional(string, "notBreaching")
      skip_ok_action      = optional(bool, true)
    }))
  }))
  default = {}
  validation {
    condition     = alltrue([for k, v in var.classified_anomaly_alarms : contains(keys(v.severities), "sev1")])
    error_message = "Every classified_anomaly_alarm must define at least sev1 (critical severity)."
  }
}
