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

# EFS File System Configuration
variable "file_systems" {
  description = "Map of EFS file system configurations"
  type = map(object({
    # Basic Configuration
    name           = string
    creation_token = optional(string)

    # Performance Configuration
    performance_mode                = optional(string, "generalPurpose") # generalPurpose or maxIO
    throughput_mode                 = optional(string, "bursting")       # bursting, provisioned, or elastic
    provisioned_throughput_in_mibps = optional(number)                   # Required if throughput_mode is provisioned

    # Encryption
    encrypted  = optional(bool, true)
    kms_key_id = optional(string)

    # Lifecycle Policies
    lifecycle_policies = optional(list(object({
      transition_to_ia                    = optional(string) # AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS, AFTER_1_DAY, AFTER_180_DAYS, AFTER_270_DAYS, AFTER_365_DAYS
      transition_to_primary_storage_class = optional(string) # AFTER_1_ACCESS
      transition_to_archive               = optional(string) # AFTER_1_DAY, AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS, AFTER_180_DAYS, AFTER_270_DAYS, AFTER_365_DAYS
    })), [])

    # Protection
    replication_overwrite_protection = optional(string) # ENABLED, DISABLED, REPLICATING

    # Backup Policy
    enable_backup_policy               = optional(bool, false)
    backup_policy_status               = optional(string, "ENABLED") # ENABLED or DISABLED
    file_system_policy                 = optional(string)
    bypass_policy_lockout_safety_check = optional(bool, false)

    # Mount Targets
    subnet_ids                = list(string)
    security_group_ids        = list(string)
    mount_target_ip_addresses = optional(map(string), {}) # Map of subnet_id to IP address

    # Access Points
    access_points = optional(map(object({
      name = string
      posix_user = optional(object({
        gid            = number
        uid            = number
        secondary_gids = optional(list(number), [])
      }))
      root_directory = optional(object({
        path = optional(string, "/")
        creation_info = optional(object({
          owner_gid   = number
          owner_uid   = number
          permissions = string
        }))
      }))
      tags = optional(map(string), {})
    })), {})

    # Replication Configuration
    replication_configuration = optional(object({
      destination_region                 = optional(string)
      destination_file_system_id         = optional(string)
      destination_availability_zone_name = optional(string)
      destination_kms_key_id             = optional(string)
    }))

    # Tags
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.file_systems :
      contains(["generalPurpose", "maxIO"], v.performance_mode)
    ])
    error_message = "Performance mode must be either 'generalPurpose' or 'maxIO'."
  }

  validation {
    condition = alltrue([
      for k, v in var.file_systems :
      contains(["bursting", "provisioned", "elastic"], v.throughput_mode)
    ])
    error_message = "Throughput mode must be 'bursting', 'provisioned', or 'elastic'."
  }

  validation {
    condition = alltrue([
      for k, v in var.file_systems :
      v.throughput_mode != "provisioned" || v.provisioned_throughput_in_mibps != null
    ])
    error_message = "Provisioned throughput must be specified when throughput_mode is 'provisioned'."
  }

  validation {
    condition = alltrue([
      for k, v in var.file_systems :
      v.replication_overwrite_protection == null ? true : contains(["ENABLED", "DISABLED", "REPLICATING"], v.replication_overwrite_protection)
    ])
    error_message = "Replication overwrite protection must be 'ENABLED', 'DISABLED', or 'REPLICATING'."
  }

  validation {
    condition = alltrue([
      for k, v in var.file_systems :
      contains(["ENABLED", "DISABLED"], v.backup_policy_status)
    ])
    error_message = "Backup policy status must be either 'ENABLED' or 'DISABLED'."
  }
}
