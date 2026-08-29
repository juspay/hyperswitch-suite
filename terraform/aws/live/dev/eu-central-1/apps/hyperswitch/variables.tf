variable "environment" {
  description = "Environment name (e.g., dev, integ, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hyperswitch"
}

variable "cluster_service_accounts" {
  description = "Map of EKS cluster names to their respective list of Kubernetes service accounts"
  type = map(list(object({
    namespace = string
    name      = string
  })))
  default = {}
}

variable "kms" {
  description = "KMS key configuration. Set to {} to disable KMS key and policy."
  type = object({
    create                           = optional(bool, false)
    key_arn                          = optional(string, null)
    description                      = optional(string, null)
    multi_region                     = optional(bool, false)
    create_replica                   = optional(bool, false)
    create_replica_external          = optional(bool, false)
    primary_key_arn                  = optional(string, null)
    primary_external_key_arn         = optional(string, null)
    create_external                  = optional(bool, false)
    key_material_base64              = optional(string, null)
    valid_to                         = optional(string, null)
    key_usage                        = optional(string, null)
    customer_master_key_spec         = optional(string, null)
    key_spec                         = optional(string, null)
    deletion_window_in_days          = optional(number, null)
    is_enabled                       = optional(bool, null)
    enable_key_rotation              = optional(bool, true)
    rotation_period_in_days          = optional(number, null)
    bypass_policy_lockout_safety_check = optional(bool, null)
    aliases                          = optional(list(string), [])
    aliases_use_name_prefix          = optional(bool, false)
    key_administrators               = optional(list(string), [])
    key_users                        = optional(list(string), [])
    key_service_users                = optional(list(string), [])
    key_owners                       = optional(list(string), [])
  })
  default = {}
}

variable "s3_dashboard_themes" {
  description = "S3 bucket configuration for dashboard themes. Set to {} to disable."
  type = object({
    create             = optional(bool, false)
    bucket_arn         = optional(string, null)
    bucket_name        = optional(string, null)
    force_destroy      = optional(bool, false)
    versioning_enabled = optional(bool, true)
  })
  default = {}
}

variable "s3_file_uploads" {
  description = "S3 bucket configuration for file uploads. Set to {} to disable."
  type = object({
    create             = optional(bool, false)
    bucket_arn         = optional(string, null)
    bucket_name        = optional(string, null)
    force_destroy      = optional(bool, false)
    versioning_enabled = optional(bool, true)
  })
  default = {}
}

variable "ses" {
  description = "SES configuration. Set to {} to disable SES policy."
  type = object({
    enabled  = optional(bool, false)
    role_arn = optional(string, null)
  })
  default = {}
}

variable "secrets_manager" {
  description = "Secrets Manager configuration. Set to {} to disable."
  type = object({
    enabled     = optional(bool, false)
    secret_arns = optional(list(string), [])
  })
  default = {}
}

variable "lambda" {
  description = "Lambda function configuration. Set to {} to disable Lambda policy."
  type = object({
    enabled       = optional(bool, false)
    function_arns = optional(list(string), [])
  })
  default = {}
}

variable "assume_role" {
  description = "Cross-account assume role configuration. Set to {} to disable."
  type = object({
    enabled          = optional(bool, false)
    target_role_arns = optional(list(string), [])
    account_id       = optional(string, null)
  })
  default = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
