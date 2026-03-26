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

variable "database_config" {
  description = "Configuration object for the RDS Aurora PostgreSQL database"
  type = object({
    subnet_ids                            = list(string)
    cluster_identifier                    = optional(string, null)
    cluster_identifier_prefix             = optional(string, null)
    database_name                         = optional(string, null)
    engine                                = optional(string, "aurora-postgresql")
    engine_version                        = optional(string, null)
    engine_mode                           = optional(string, "provisioned")
    engine_lifecycle_support              = optional(string, "open-source-rds-extended-support")
    cluster_scalability_type              = optional(string, null)
    master_username                       = string
    master_password                       = optional(string, null)
    manage_master_user_password           = optional(bool, null)
    master_user_secret_kms_key_id         = optional(string, null)
    db_cluster_instance_class             = optional(string, null)
    availability_zones                    = list(string)
    allocated_storage                     = optional(number, null)
    storage_type                          = optional(string, "aurora-iopt1")
    iops                                  = optional(number, null)
    network_type                          = optional(string, "IPV4")
    port                                  = optional(number, 5432)
    create_db_subnet_group                = optional(bool, true)
    db_subnet_group_name                  = optional(string, null)
    vpc_security_group_ids                = optional(list(string), [])
    db_cluster_parameter_group_name       = optional(string, "default.aurora-postgresql17")
    db_instance_parameter_group_name      = optional(string, null)
    backup_retention_period               = optional(number, 7)
    preferred_backup_window               = optional(string, "00:51-01:21")
    preferred_maintenance_window          = optional(string, "thu:00:12-thu:00:42")
    skip_final_snapshot                   = optional(bool, true)
    final_snapshot_identifier             = optional(string, null)
    snapshot_identifier                   = optional(string, null)
    copy_tags_to_snapshot                 = optional(bool, false)
    storage_encrypted                     = optional(bool, true)
    kms_key_id                            = optional(string, null)
    deletion_protection                   = optional(bool, false)
    delete_automated_backups              = optional(bool, true)
    iam_database_authentication_enabled   = optional(bool, false)
    iam_roles                             = optional(list(string), [])
    domain                                = optional(string, null)
    domain_iam_role_name                  = optional(string, null)
    allow_major_version_upgrade           = optional(bool, null)
    apply_immediately                     = optional(bool, null)
    enabled_cloudwatch_logs_exports       = optional(list(string), ["postgresql"])
    performance_insights_enabled          = optional(bool, false)
    performance_insights_kms_key_id       = optional(string, null)
    performance_insights_retention_period = optional(number, 0)
    monitoring_interval                   = optional(number, 0)
    monitoring_role_arn                   = optional(string, null)
    database_insights_mode                = optional(string, "standard")
    enable_http_endpoint                  = optional(bool, false)
    enable_local_write_forwarding         = optional(bool, null)
    replication_source_identifier         = optional(string, null)
    source_region                         = optional(string, null)
    backtrack_window                      = optional(number, 0)
    ca_certificate_identifier             = optional(string, null)
    db_system_id                          = optional(string, null)
    create_security_group                 = optional(bool, true)
    security_group_name                   = optional(string, null)
    security_group_description            = optional(string, null)
    scaling_configuration                 = optional(any, null)
    serverlessv2_scaling_configuration    = optional(any, null)
    restore_to_point_in_time              = optional(any, null)
    s3_import                             = optional(any, null)
    create_global_cluster                 = optional(bool, false)
    global_cluster_identifier             = optional(string, null)
    global_deletion_protection            = optional(bool, true)
    enable_global_write_forwarding        = optional(bool, false)
    use_existing_as_global_primary        = optional(bool, false)
    source_db_cluster_identifier          = optional(string, null)
    create_custom_parameter_group         = optional(bool, false)
    custom_parameter_group_name           = optional(string, null)
    custom_parameter_group_family         = optional(string, null)
    custom_parameter_group_description    = optional(string, null)
    custom_parameter_group_parameters     = optional(list(map(string)), [])
    cluster_instances = optional(map(object({
      identifier                            = optional(string)
      identifier_prefix                     = optional(string)
      instance_class                        = string
      engine                                = optional(string)
      engine_version                        = optional(string)
      publicly_accessible                   = optional(bool)
      db_parameter_group_name               = optional(string)
      apply_immediately                     = optional(bool)
      monitoring_role_arn                   = optional(string)
      monitoring_interval                   = optional(number)
      promotion_tier                        = optional(number)
      availability_zone                     = optional(string)
      preferred_backup_window               = optional(string)
      preferred_maintenance_window          = optional(string)
      auto_minor_version_upgrade            = optional(bool)
      performance_insights_enabled          = optional(bool)
      performance_insights_kms_key_id       = optional(string)
      performance_insights_retention_period = optional(number)
      copy_tags_to_snapshot                 = optional(bool)
      ca_cert_identifier                    = optional(string)
      custom_iam_instance_profile           = optional(string)
      force_destroy                         = optional(bool)
      tags                                  = optional(map(string))
    })), {})
    tags = optional(map(string), {})
  })
  default = null
}