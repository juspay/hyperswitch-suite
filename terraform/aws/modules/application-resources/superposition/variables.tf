variable "region" {
  description = "AWS region"
  type        = string
}

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

variable "role_name" {
  description = "Custom IAM role name. If null, auto-generated as {project}-{env}-{app}-role"
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

variable "oidc_providers" {
  description = "OIDC provider trust for EKS service accounts"
  type = map(object({
    provider_arn = string
    conditions = list(object({
      type   = string
      claim  = string
      values = list(string)
    }))
  }))
  default = null
}

variable "assume_role_principals" {
  description = "Cross-account assume role trust"
  type = list(object({
    type        = string
    identifiers = list(string)
  }))
  default = null
}

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

variable "create_database" {
  description = "Whether to create a database for Superposition"
  type        = bool
  default     = false
}

variable "database_vpc_id" {
  description = "VPC ID where the database will be created (required if create_database is true)"
  type        = string
  default     = null
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for the database subnet group (required if create_database is true)"
  type        = list(string)
  default     = []
}

variable "database_cluster_identifier" {
  description = "Custom cluster identifier for the database. If null, auto-generated"
  type        = string
  default     = null
}

variable "database_engine" {
  description = "Database engine to use"
  type        = string
  default     = "aurora-postgresql"
}

variable "database_engine_version" {
  description = "Database engine version"
  type        = string
  default     = null
}

variable "database_engine_mode" {
  description = "Database engine mode. Valid values: global, parallelquery, provisioned, serverless"
  type        = string
  default     = "provisioned"
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = null
}

variable "database_master_username" {
  description = "Master username for the database"
  type        = string
  default     = null
}

variable "database_master_password" {
  description = "Master password for the database"
  type        = string
  default     = null
  sensitive   = true
}

variable "database_manage_master_user_password" {
  description = "Whether to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = true
}

variable "database_cluster_instances" {
  description = "Map of cluster instances to create"
  type = map(object({
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
  }))
  default = {}
}

variable "database_serverlessv2_scaling_configuration" {
  description = "Serverless v2 scaling configuration"
  type = object({
    max_capacity             = number
    min_capacity             = number
    seconds_until_auto_pause = optional(number)
  })
  default = null
}

variable "database_backup_retention_period" {
  description = "Days to retain backups for"
  type        = number
  default     = 7
}

variable "database_preferred_backup_window" {
  description = "Daily time range during which automated backups are created (UTC)"
  type        = string
  default     = null
}

variable "database_preferred_maintenance_window" {
  description = "Weekly time range during which system maintenance can occur (UTC)"
  type        = string
  default     = null
}

variable "database_skip_final_snapshot" {
  description = "Whether to skip final snapshot on deletion"
  type        = bool
  default     = false
}

variable "database_final_snapshot_identifier" {
  description = "Name of the final DB snapshot when cluster is deleted"
  type        = string
  default     = null
}

variable "database_deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = false
}

variable "database_storage_encrypted" {
  description = "Whether to encrypt storage"
  type        = bool
  default     = true
}

variable "database_kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "database_vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the database"
  type        = list(string)
  default     = []
}

variable "database_create_security_group" {
  description = "Whether to create a security group for the database"
  type        = bool
  default     = true
}

variable "database_enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

variable "database_performance_insights_enabled" {
  description = "Whether to enable Performance Insights"
  type        = bool
  default     = false
}

variable "database_performance_insights_kms_key_id" {
  description = "KMS key ID for Performance Insights encryption"
  type        = string
  default     = null
}

variable "database_performance_insights_retention_period" {
  description = "Retention period for Performance Insights data"
  type        = number
  default     = 7
}

variable "database_iam_database_authentication_enabled" {
  description = "Whether to enable IAM database authentication"
  type        = bool
  default     = false
}

variable "database_create_custom_parameter_group" {
  description = "Whether to create a custom parameter group"
  type        = bool
  default     = false
}

variable "database_custom_parameter_group_family" {
  description = "Family for the custom parameter group"
  type        = string
  default     = null
}

variable "database_custom_parameter_group_parameters" {
  description = "List of parameters for custom parameter group"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}
