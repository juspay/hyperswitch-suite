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

# CloudWatch Metric Anomaly Detection Alarms
variable "metric_anomaly_alarms" {
  description = "Map of CloudWatch metric anomaly detection alarms using ANOMALY_DETECTION_BAND"
  type = map(object({
    alarm_name         = optional(string) # Derived from key if not provided
    alarm_description  = optional(string)
    metric_name        = string
    namespace          = string
    period             = optional(number, 300) # in seconds
    statistic          = optional(string, "Average")
    dimensions         = optional(map(string), {})
    evaluation_periods = optional(number, 2)
    # Anomaly band detection: triggers when metric goes outside the expected band
    comparison_operator       = optional(string, "GreaterThanUpperThreshold") # GreaterThanUpperThreshold, LessThanLowerThreshold
    standard_deviations       = optional(number, 2)                           # Number of standard deviations for the band (1, 2, or 3)
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    treat_missing_data        = optional(string, "missing")
  }))
  default = {}
}

# Classified Metric Alarms with Multi-Threshold Support
variable "classified_metric_alarms" {
  description = "Map of classified metric alarms with multi-threshold severity levels. Each alarm can define multiple thresholds (sev1, sev2, sev3) that generate separate alarms."
  type = map(object({
    classification = optional(string, "infrastructure-alerts") # Classification category: rds-alerts, cache-alerts, eks-alerts, etc.
    metric_name    = string
    namespace      = string
    dimensions     = optional(map(string), {})
    period         = optional(number, 60)
    statistic      = optional(string, "Average")
    # Multi-threshold configuration - each threshold creates a separate alarm
    thresholds = map(object({
      threshold           = number
      evaluation_periods  = optional(number, 3)
      datapoints_to_alarm = optional(number)
      treat_missing_data  = optional(string, "notBreaching")
    }))
    # Severity configurations - maps threshold keys to severity settings
    severity_config = map(object({
      severity            = string                                   # sev1, sev2, or sev3
      description         = string                                   # Alarm description
      alarm_actions       = optional(list(string), [])               # SNS topic ARNs
      ok_actions          = optional(list(string), [])               # SNS topic ARNs
      comparison_operator = optional(string, "GreaterThanThreshold") # or "LessThanThreshold"
    }))
  }))
  default = {}
}


