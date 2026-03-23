variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "superposition"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =========================================================================
# EKS OIDC Configuration
# =========================================================================

variable "cluster_service_accounts" {
  description = "Map of EKS cluster names to their respective list of Kubernetes service accounts (namespace and service account name)"
  type = map(list(object({
    namespace = string
    name      = string
  })))
  default = {}
}

variable "additional_assume_role_statements" {
  description = "Additional IAM assume role policy statements to append"
  type        = list(any)
  default     = []
}

# =========================================================================
# IAM Role Configuration
# =========================================================================

variable "role_name" {
  description = "Custom IAM role name. If null, auto-generated as {environment}-{project}-{app}-role"
  type        = string
  default     = null
}

variable "role_description" {
  description = "Custom IAM role description"
  type        = string
  default     = null
}

variable "role_path" {
  description = "IAM role path"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration for the role (in seconds)"
  type        = number
  default     = 3600
}

variable "force_detach_policies" {
  description = "Whether to force detaching policies when destroying the role"
  type        = bool
  default     = true
}

# =========================================================================
# Assume Role Principals
# =========================================================================

variable "assume_role_principals" {
  description = "List of AWS principal ARNs allowed to assume this role (e.g., ['arn:aws:iam::123456789012:root'])"
  type        = list(string)
  default     = []
}

# =========================================================================
# Policy Attachments
# =========================================================================

variable "aws_managed_policy_names" {
  description = "List of AWS managed policy names to attach"
  type        = list(string)
  default     = []
}

variable "customer_managed_policy_arns" {
  description = "List of customer managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

# =========================================================================
# Inline Policies
# =========================================================================

variable "inline_policies" {
  description = "Map of inline policies for role-specific permissions"
  type        = map(string)
  default     = {}
}

# =========================================================================
# Database Configuration
# =========================================================================

variable "database" {
  description = "Database configuration object"
  type = object({
    enabled                     = optional(bool, false)
    vpc_id                      = optional(string, null)
    subnet_ids                  = optional(list(string), [])
    cluster_identifier          = optional(string, null)
    engine                      = optional(string, "aurora-postgresql")
    engine_version              = optional(string, null)
    engine_mode                 = optional(string, "provisioned")
    database_name               = optional(string, null)
    master_username             = optional(string, null)
    master_password             = optional(string, null)
    manage_master_user_password = optional(bool, true)
    cluster_instances = optional(map(object({
      identifier                            = optional(string)
      identifier_prefix                     = optional(string)
      instance_class                        = string
      engine                                = optional(string)
      engine_version                        = optional(string)
      publicly_accessible                   = optional(bool, false)
      db_parameter_group_name               = optional(string)
      apply_immediately                     = optional(bool, null)
      monitoring_role_arn                   = optional(string)
      monitoring_interval                   = optional(number, 0)
      promotion_tier                        = optional(number, 0)
      availability_zone                     = optional(string)
      preferred_backup_window               = optional(string)
      preferred_maintenance_window          = optional(string)
      auto_minor_version_upgrade            = optional(bool, true)
      performance_insights_enabled          = optional(bool)
      performance_insights_kms_key_id       = optional(string)
      performance_insights_retention_period = optional(number, 7)
      copy_tags_to_snapshot                 = optional(bool, false)
      ca_cert_identifier                    = optional(string)
      custom_iam_instance_profile           = optional(string)
      force_destroy                         = optional(bool, false)
      tags                                  = optional(map(string), {})
    })), {})
    serverlessv2_scaling_configuration = optional(object({
      max_capacity             = number
      min_capacity             = number
      seconds_until_auto_pause = optional(number)
    }), null)
    backup_retention_period               = optional(number, 7)
    preferred_backup_window               = optional(string, null)
    preferred_maintenance_window          = optional(string, null)
    skip_final_snapshot                   = optional(bool, false)
    final_snapshot_identifier             = optional(string, null)
    deletion_protection                   = optional(bool, false)
    storage_encrypted                     = optional(bool, true)
    kms_key_id                            = optional(string, null)
    vpc_security_group_ids                = optional(list(string), [])
    create_security_group                 = optional(bool, true)
    enabled_cloudwatch_logs_exports       = optional(list(string), [])
    performance_insights_enabled          = optional(bool, false)
    performance_insights_kms_key_id       = optional(string, null)
    performance_insights_retention_period = optional(number, 7)
    iam_database_authentication_enabled   = optional(bool, false)
    create_custom_parameter_group         = optional(bool, false)
    custom_parameter_group_name           = optional(string, null)
    custom_parameter_group_family         = optional(string, null)
    custom_parameter_group_description    = optional(string, null)
    custom_parameter_group_parameters = optional(list(object({
      name         = string
      value        = string
      apply_method = optional(string, "immediate")
    })), [])
  })
  default = {}
}
