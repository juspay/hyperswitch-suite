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

variable "database_db_subnet_group_name" {
  description = "Existing DB subnet group name to reuse (if create_db_subnet_group is false)"
  type        = string
  default     = null
}

variable "database_create_db_subnet_group" {
  description = "Whether to create a new DB subnet group. Set to false to reuse an existing subnet group"
  type        = bool
  default     = true
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

variable "database_security_group_name" {
  description = "Custom name for the database security group (if create_security_group is true)"
  type        = string
  default     = null
}

variable "database_security_group_description" {
  description = "Custom description for the database security group"
  type        = string
  default     = null
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

variable "database_custom_parameter_group_name" {
  description = "Custom name for the parameter group"
  type        = string
  default     = null
}

variable "database_custom_parameter_group_description" {
  description = "Description for the custom parameter group"
  type        = string
  default     = null
}

variable "database_db_cluster_parameter_group_name" {
  description = "Existing cluster parameter group to associate with the cluster"
  type        = string
  default     = null
}

variable "database_db_instance_parameter_group_name" {
  description = "Instance parameter group to associate with all instances of the DB cluster"
  type        = string
  default     = null
}

variable "database_engine_lifecycle_support" {
  description = "The life cycle type for this DB instance. Valid values: open-source-rds-extended-support, open-source-rds-extended-support-disabled"
  type        = string
  default     = null
}

variable "database_availability_zones" {
  description = "List of EC2 Availability Zones for the DB cluster storage"
  type        = list(string)
  default     = null
}

variable "database_allocated_storage" {
  description = "Amount of storage in GiB to allocate (for Multi-AZ DB cluster)"
  type        = number
  default     = null
}

variable "database_storage_type" {
  description = "Storage type. Valid values for Aurora: aurora-iopt1. Valid values for Multi-AZ: io1, io2"
  type        = string
  default     = null
}

variable "database_iops" {
  description = "Provisioned IOPS for each DB instance in Multi-AZ cluster"
  type        = number
  default     = null
}

variable "database_db_cluster_instance_class" {
  description = "Compute and memory capacity of each DB instance in Multi-AZ cluster"
  type        = string
  default     = null
}

variable "database_network_type" {
  description = "Network type of the cluster. Valid values: IPV4, DUAL"
  type        = string
  default     = null
}

variable "database_port" {
  description = "Port on which the DB accepts connections"
  type        = number
  default     = null
}

variable "database_copy_tags_to_snapshot" {
  description = "Copy all Cluster tags to snapshots"
  type        = bool
  default     = false
}

variable "database_delete_automated_backups" {
  description = "Whether to remove automated backups immediately after cluster deletion"
  type        = bool
  default     = true
}

variable "database_monitoring_interval" {
  description = "Interval in seconds between Enhanced Monitoring metrics collection. Valid: 0, 1, 5, 10, 15, 30, 60"
  type        = number
  default     = 0
}

variable "database_monitoring_role_arn" {
  description = "ARN for IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch"
  type        = string
  default     = null
}

variable "database_database_insights_mode" {
  description = "Mode of Database Insights. Valid values: standard, advanced"
  type        = string
  default     = null
}

variable "database_enable_http_endpoint" {
  description = "Enable HTTP endpoint (Data API)"
  type        = bool
  default     = false
}

variable "database_backtrack_window" {
  description = "Target backtrack window in seconds (0 to disable, max 259200 for 72 hours)"
  type        = number
  default     = 0
}

variable "database_snapshot_identifier" {
  description = "Specifies whether to create this cluster from a snapshot"
  type        = string
  default     = null
}

variable "database_apply_immediately" {
  description = "Specifies whether cluster modifications are applied immediately or during next maintenance window"
  type        = bool
  default     = null
}

variable "database_allow_major_version_upgrade" {
  description = "Enable to allow major engine version upgrades"
  type        = bool
  default     = null
}

variable "database_scaling_configuration" {
  description = "Scaling configuration for Serverless v1 (only valid when engine_mode is serverless)"
  type = object({
    auto_pause               = optional(bool, true)
    max_capacity             = optional(number, 16)
    min_capacity             = optional(number, 1)
    seconds_before_timeout   = optional(number, 300)
    seconds_until_auto_pause = optional(number, 300)
    timeout_action           = optional(string, "RollbackCapacityChange")
  })
  default = null
}

variable "database_iam_roles" {
  description = "List of ARNs for IAM roles to associate with the RDS Cluster"
  type        = list(string)
  default     = []
}

variable "database_ca_certificate_identifier" {
  description = "CA certificate identifier to use for the DB cluster's server certificate"
  type        = string
  default     = null
}

variable "database_master_user_secret_kms_key_id" {
  description = "KMS key identifier for encrypting the master user password in Secrets Manager"
  type        = string
  default     = null
}

# =========================================================================
# Database Global Cluster Configuration
# =========================================================================

variable "database_create_global_cluster" {
  description = "Whether to create a global cluster for multi-region deployment"
  type        = bool
  default     = false
}

variable "database_global_cluster_identifier" {
  description = "Global cluster identifier to which this cluster should belong"
  type        = string
  default     = null
}

variable "database_global_deletion_protection" {
  description = "Whether deletion protection is enabled for the global cluster"
  type        = bool
  default     = true
}

variable "database_enable_global_write_forwarding" {
  description = "Whether cluster should forward writes to an associated global cluster"
  type        = bool
  default     = false
}

variable "database_use_existing_as_global_primary" {
  description = "Whether to use existing cluster as primary for global database"
  type        = bool
  default     = false
}

variable "database_source_db_cluster_identifier" {
  description = "ARN of existing cluster to use as primary for global database"
  type        = string
  default     = null
}
