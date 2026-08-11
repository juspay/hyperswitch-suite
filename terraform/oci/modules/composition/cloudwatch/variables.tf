variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "metric_alarms" {
  description = "Map of alarm key -> config. Equivalent of AWS var.metric_alarms."
  type = map(object({
    display_name                 = string
    query                        = string # MQL query, e.g. "CpuUtilization[1m].mean() > 80"
    metric_compartment_id        = optional(string)
    namespace                    = string
    severity                     = optional(string, "WARNING") # CRITICAL | ERROR | WARNING | INFO
    destinations                 = list(string)                # ONS topic OCIDs
    pending_duration             = optional(string, "PT1M")
    is_enabled                   = optional(bool, true)
    body                         = optional(string)
    repeat_notification_duration = optional(string)
    resource_group               = optional(string)
  }))
  default = {}
}

variable "log_groups" {
  description = "Map of log group key -> display name. Equivalent of AWS var.log_groups."
  type        = map(string)
  default     = {}
}

variable "custom_logs" {
  description = <<-EOT
    Map of custom-log key -> config (custom logs, e.g. application logs pushed
    via the Unified Monitoring Agent). Equivalent of AWS CloudWatch Log
    Streams. log_group_key must reference a key in var.log_groups.
  EOT
  type = map(object({
    log_group_key      = string
    display_name       = string
    retention_duration = optional(number, 30)
  }))
  default = {}
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
