# General Variables
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
  description = "(Optional) Region where this resource will be managed. Defaults to the Region set in the provider configuration"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# CloudWatch Metric Alarms Configuration
variable "metric_alarms" {
  description = "Map of CloudWatch metric alarms"
  type = map(object({
    alarm_name                = string
    alarm_description         = optional(string, "")
    comparison_operator       = string # GreaterThanThreshold, LessThanThreshold, GreaterThanOrEqualToThreshold, LessThanOrEqualToThreshold
    evaluation_periods        = number
    metric_name               = string
    namespace                 = string
    period                    = number # in seconds
    statistic                 = string # Average, Sum, Maximum, Minimum, SampleCount
    threshold                 = number
    dimensions                = optional(map(string), {})
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    treat_missing_data        = optional(string, "missing") # breaching, notBreaching, missing, ignoreMetricTime
    datapoints_to_alarm       = optional(number)
    threshold_metric_id       = optional(string)
  }))
  default = {}
}

# CloudWatch Composite Alarms Configuration
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

# CloudWatch Log Groups Configuration
variable "log_groups" {
  description = "Map of CloudWatch log groups"
  type = map(object({
    name              = string
    retention_in_days = optional(number, 7)
    kms_key_id        = optional(string)
    log_streams       = optional(map(string), {}) # key -> stream name
  }))
  default = {}
}

# CloudWatch Log Group Policies Configuration
variable "log_resource_policies" {
  description = "Map of CloudWatch log group resource policies"
  type = map(object({
    policy_name     = string
    policy_document = string
  }))
  default = {}
}

# CloudWatch Dashboards Configuration
variable "dashboards" {
  description = "Map of CloudWatch dashboards"
  type = map(object({
    dashboard_name = string
    dashboard_body = string # JSON string
  }))
  default = {}
}


