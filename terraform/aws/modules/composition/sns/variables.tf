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

# SNS Topic Configuration
variable "topics" {
  description = "Map of SNS topic configurations"
  type = map(object({
    name                        = string
    display_name                = optional(string, "")
    kms_master_key_id           = optional(string)
    fifo_topic                  = optional(bool, false)
    content_based_deduplication = optional(bool, false)
    policy                      = optional(string)
    data_protection_policy      = optional(string)
    subscriptions = optional(map(object({
      protocol                        = string
      endpoint                        = string
      filter_policy                   = optional(string)
      raw_message_delivery            = optional(bool, false)
      redrive_policy                  = optional(string)
      delivery_policy                 = optional(string)
      endpoint_auto_confirms          = optional(bool, false)
      confirmation_timeout_in_minutes = optional(number, 1440)
    })), {})
  }))
  default = {}
}
