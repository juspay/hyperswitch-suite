variable "project_id" {
  description = "GCP project ID where monitoring resources are created"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "notification_channels" {
  description = "Map of notification channels to create, keyed by logical name"
  type = map(object({
    type        = string # e.g. "email", "pubsub", "slack", "pagerduty"
    labels      = map(string)
    description = optional(string)
    enabled     = optional(bool, true)
  }))
  default = {}
}

variable "alert_policies" {
  description = "Map of alert policies to create, keyed by logical name. notification_channel_keys reference keys in var.notification_channels"
  type = map(object({
    combiner = string # AND, OR, AND_WITH_MATCHING_RESOURCE
    conditions = list(object({
      display_name       = string
      filter             = string
      comparison         = string # COMPARISON_GT, COMPARISON_LT, ...
      threshold_value    = number
      duration           = string
      alignment_period   = optional(string, "60s")
      per_series_aligner = optional(string, "ALIGN_MEAN")
    }))
    notification_channel_keys = optional(list(string), [])
    documentation             = optional(string)
    labels                    = optional(map(string), {})
  }))
  default = {}
}

variable "log_metrics" {
  description = "Map of log-based metrics to create, keyed by logical name"
  type = map(object({
    filter      = string
    description = optional(string)
    metric_kind = optional(string, "DELTA")
    value_type  = optional(string, "INT64")
    unit        = optional(string, "1")
  }))
  default = {}
}

variable "dashboards" {
  description = "Map of dashboard definitions (as native Terraform objects, JSON-encoded internally) keyed by logical name"
  type        = map(any)
  default     = {}
}

variable "log_sinks" {
  description = "Map of project-level log sinks to create, keyed by logical name"
  type = map(object({
    destination_uri = string # e.g. "storage.googleapis.com/<bucket>" or "pubsub.googleapis.com/projects/<p>/topics/<t>"
    filter          = string
  }))
  default = {}
}
