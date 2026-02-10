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

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS DB subnet group"
  type        = list(string)
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# RDS Cluster Core Configuration (Required)
variable "cluster_identifier" {
  description = "(Optional, Forces new resource) The cluster identifier. If omitted, Terraform will assign a random, unique identifier"
  type        = string
  default     = null
}

variable "cluster_identifier_prefix" {
  description = "(Optional, Forces new resource) Creates a unique cluster identifier beginning with the specified prefix. Conflicts with cluster_identifier"
  type        = string
  default     = null
}

variable "engine" {
  description = "(Required) Name of the database engine to be used for this DB cluster. Valid Values: aurora-mysql, aurora-postgresql, mysql, postgres"
  type        = string
  default     = "aurora-postgresql"

  validation {
    condition     = contains(["aurora-mysql", "aurora-postgresql", "mysql", "postgres"], var.engine)
    error_message = "engine must be one of: aurora-mysql, aurora-postgresql, mysql, postgres."
  }
}

variable "engine_version" {
  description = "(Optional) Database engine version. Updating this argument results in an outage"
  type        = string
  default     = null
}

variable "engine_mode" {
  description = "(Optional) Database engine mode. Valid values: global, parallelquery, provisioned, serverless"
  type        = string
  default     = "provisioned"

  validation {
    condition     = var.engine_mode == null || contains(["global", "parallelquery", "provisioned", "serverless", ""], var.engine_mode)
    error_message = "engine_mode must be one of: global, parallelquery, provisioned, serverless, or empty string."
  }
}

variable "engine_lifecycle_support" {
  description = "(Optional) The life cycle type for this DB instance. Valid values are open-source-rds-extended-support, open-source-rds-extended-support-disabled"
  type        = string
  default     = "open-source-rds-extended-support"

  validation {
    condition     = var.engine_lifecycle_support == null || contains(["open-source-rds-extended-support", "open-source-rds-extended-support-disabled"], var.engine_lifecycle_support)
    error_message = "engine_lifecycle_support must be one of: open-source-rds-extended-support, open-source-rds-extended-support-disabled."
  }
}

# Database Configuration
variable "database_name" {
  description = "(Optional) Name for an automatically created database on cluster creation"
  type        = string
  default     = null
}

variable "master_username" {
  description = "(Required unless a snapshot_identifier or replication_source_identifier is provided) Username for the master DB user"
  type        = string
  default     = null
}

variable "master_password" {
  description = "(Optional, required unless manage_master_user_password is true or snapshot_identifier is provided) Password for the master DB user"
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "(Optional) Set to true to allow RDS to manage the master user password in Secrets Manager. Cannot be set if master_password is provided"
  type        = bool
  default     = null
}

variable "master_user_secret_kms_key_id" {
  description = "(Optional) KMS key identifier for encrypting the master user password in Secrets Manager"
  type        = string
  default     = null
}

# Multi-AZ Cluster Configuration
variable "db_cluster_instance_class" {
  description = "(Optional, Required for Multi-AZ DB cluster) The compute and memory capacity of each DB instance in the Multi-AZ DB cluster"
  type        = string
  default     = null
}

variable "allocated_storage" {
  description = "(Optional, Required for Multi-AZ DB cluster) The amount of storage in gibibytes (GiB) to allocate to each DB instance in the Multi-AZ DB cluster"
  type        = number
  default     = null
}

variable "storage_type" {
  description = "(Optional) Specifies the storage type. Valid values for Aurora: aurora-iopt1. Valid values for Multi-AZ: io1, io2"
  type        = string
  default     = null
}

variable "iops" {
  description = "(Optional) Amount of Provisioned IOPS for each DB instance in the Multi-AZ DB cluster. Must be a multiple between .5 and 50 of the storage amount"
  type        = number
  default     = null
}

# Cluster Scalability
variable "cluster_scalability_type" {
  description = "(Optional, Forces new resource) Specifies the scalability mode. Valid values: limitless, standard"
  type        = string
  default     = null

  validation {
    condition     = var.cluster_scalability_type == null || contains(["limitless", "standard"], var.cluster_scalability_type)
    error_message = "cluster_scalability_type must be one of: limitless, standard."
  }
}

# Network Configuration
variable "availability_zones" {
  description = "(Optional) List of EC2 Availability Zones for the DB cluster storage. RDS automatically assigns 3 AZs if less than 3 are configured"
  type        = list(string)
  default     = null
  validation {
    condition = length(var.availability_zones) >= 3 || var.availability_zones == null
    error_message = "Minimum of 3 Availability Zones (or null) are required"
  }
}

variable "db_subnet_group_name" {
  description = "(Optional) DB subnet group to associate with this DB cluster"
  type        = string
  default     = null
}

variable "create_db_subnet_group" {
  description = "Whether to create a new DB subnet group"
  type        = bool
  default     = true
}

variable "vpc_security_group_ids" {
  description = "(Optional) List of VPC security groups to associate with the Cluster"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Whether to create a new security group for RDS"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "(Optional) Name for the security group. If not provided, will be auto-generated"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "(Optional) Description for the security group"
  type        = string
  default     = null
}

variable "network_type" {
  description = "(Optional) Network type of the cluster. Valid values: IPV4, DUAL"
  type        = string
  default     = "IPV4"

  validation {
    condition     = var.network_type == null || contains(["IPV4", "DUAL"], var.network_type)
    error_message = "network_type must be one of: IPV4, DUAL."
  }
}

variable "port" {
  description = "(Optional) Port on which the DB accepts connections"
  type        = number
  default     = null
}

# Parameter Groups
variable "db_cluster_parameter_group_name" {
  description = "(Optional) A cluster parameter group to associate with the cluster"
  type        = string
  default     = null
}

variable "db_instance_parameter_group_name" {
  description = "(Optional) Instance parameter group to associate with all instances of the DB cluster"
  type        = string
  default     = null
}

# Backup and Maintenance
variable "backup_retention_period" {
  description = "(Optional) Days to retain backups for. Default 1"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "(Optional) Daily time range during which automated backups are created (UTC)"
  type        = string
  default     = null
}

variable "preferred_maintenance_window" {
  description = "(Optional) Weekly time range during which system maintenance can occur (UTC)"
  type        = string
  default     = null
}

variable "skip_final_snapshot" {
  description = "(Optional) Determines whether a final DB snapshot is created before the DB cluster is deleted"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "(Optional) Name of your final DB snapshot when this DB cluster is deleted"
  type        = string
  default     = null
}

variable "snapshot_identifier" {
  description = "(Optional) Specifies whether or not to create this cluster from a snapshot"
  type        = string
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "(Optional) Copy all Cluster tags to snapshots"
  type        = bool
  default     = false
}

# Security and Encryption
variable "storage_encrypted" {
  description = "(Optional) Specifies whether the DB cluster is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "(Optional) ARN for the KMS encryption key"
  type        = string
  default     = null
}

variable "iam_database_authentication_enabled" {
  description = "(Optional) Specifies whether IAM database authentication is enabled"
  type        = bool
  default     = false
}

variable "iam_roles" {
  description = "(Optional) List of ARNs for the IAM roles to associate to the RDS Cluster"
  type        = list(string)
  default     = []
}

# Domain Join (Active Directory)
variable "domain" {
  description = "(Optional) The ID of the Directory Service Active Directory domain to create the cluster in"
  type        = string
  default     = null
}

variable "domain_iam_role_name" {
  description = "(Optional) The name of the IAM role to be used when making API calls to the Directory Service"
  type        = string
  default     = null
}

# Deletion Protection
variable "deletion_protection" {
  description = "(Optional) If the DB cluster should have deletion protection enabled"
  type        = bool
  default     = false
}

variable "delete_automated_backups" {
  description = "(Optional) Specifies whether to remove automated backups immediately after the DB cluster is deleted"
  type        = bool
  default     = true
}

# Version Management
variable "allow_major_version_upgrade" {
  description = "(Optional) Enable to allow major engine version upgrades when changing engine versions"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "(Optional) Specifies whether any cluster modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

# Monitoring
variable "enabled_cloudwatch_logs_exports" {
  description = "(Optional) Set of log types to export to CloudWatch. Valid values: audit, error, general, iam-db-auth-error, instance, postgresql, slowquery"
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "(Optional) Enables Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "(Optional) KMS Key ID to encrypt Performance Insights data"
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "(Optional) Amount of time to retain performance insights data. Valid values: 7, month * 31 (1-23), 731"
  type        = number
  default     = 7
}

variable "monitoring_interval" {
  description = "(Optional) Interval, in seconds, between points when Enhanced Monitoring metrics are collected. Valid Values: 0, 1, 5, 10, 15, 30, 60"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "monitoring_role_arn" {
  description = "(Optional) ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
  type        = string
  default     = null
}

variable "database_insights_mode" {
  description = "(Optional) The mode of Database Insights to enable. Valid values: standard, advanced"
  type        = string
  default     = null

  validation {
    condition     = var.database_insights_mode == null || contains(["standard", "advanced"], var.database_insights_mode)
    error_message = "database_insights_mode must be one of: standard, advanced."
  }
}

# Serverless Configuration (Serverless v1)
variable "scaling_configuration" {
  description = "(Optional) Nested attribute with scaling properties for Serverless v1. Only valid when engine_mode is set to serverless"
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

# Serverless v2 Configuration
variable "serverlessv2_scaling_configuration" {
  description = "(Optional) Nested attribute with scaling properties for ServerlessV2. Only valid when engine_mode is set to provisioned"
  type = object({
    max_capacity             = number
    min_capacity             = number
    seconds_until_auto_pause = optional(number)
  })
  default = null
}

# Global Cluster
variable "global_cluster_identifier" {
  description = "(Optional) Global cluster identifier to which this replication group should belong"
  type        = string
  default     = null
}

variable "enable_global_write_forwarding" {
  description = "(Optional) Whether cluster should forward writes to an associated global cluster"
  type        = bool
  default     = false
}

# Local Write Forwarding
variable "enable_local_write_forwarding" {
  description = "(Optional) Whether read replicas can forward write operations to the writer DB instance"
  type        = bool
  default     = false
}

# HTTP Endpoint (Data API)
variable "enable_http_endpoint" {
  description = "(Optional) Enable HTTP endpoint (data API). Only valid for some combinations of engine_mode, engine and engine_version"
  type        = bool
  default     = false
}

# Replication
variable "replication_source_identifier" {
  description = "(Optional) ARN of a source DB cluster or DB instance if this DB cluster is to be created as a Read Replica"
  type        = string
  default     = null
}

variable "source_region" {
  description = "(Optional) The source region for an encrypted replica DB cluster"
  type        = string
  default     = null
}

# Point-in-Time Restore
variable "restore_to_point_in_time" {
  description = "(Optional) Nested attribute for point in time restore"
  type = object({
    source_cluster_identifier  = optional(string)
    source_cluster_resource_id = optional(string)
    restore_type               = optional(string, "full-copy")
    use_latest_restorable_time = optional(bool, false)
    restore_to_time            = optional(string)
  })
  default = null
}

# S3 Import
variable "s3_import" {
  description = "(Optional) Nested attribute for importing data from S3"
  type = object({
    bucket_name           = string
    bucket_prefix         = optional(string)
    ingestion_role        = string
    source_engine         = string
    source_engine_version = string
  })
  default = null
}

# Backtrack
variable "backtrack_window" {
  description = "(Optional) Target backtrack window, in seconds. Only available for aurora and aurora-mysql engines. To disable backtracking, set to 0"
  type        = number
  default     = 0

  validation {
    condition     = var.backtrack_window >= 0 && var.backtrack_window <= 259200
    error_message = "backtrack_window must be between 0 and 259200 (72 hours)."
  }
}

# CA Certificate
variable "ca_certificate_identifier" {
  description = "(Optional) The CA certificate identifier to use for the DB cluster's server certificate"
  type        = string
  default     = null
}

# Custom DB System
variable "db_system_id" {
  description = "(Optional) For use with RDS Custom"
  type        = string
  default     = null
}

# RDS Cluster Instances
variable "cluster_instances" {
  description = "(Optional) Map of cluster instances to create. Each instance can have its own configuration"
  type = map(object({
    identifier                            = optional(string)
    identifier_prefix                     = optional(string)
    instance_class                        = string
    engine                                = optional(string)
    engine_version                        = optional(string)
    publicly_accessible                   = optional(bool, false)
    db_parameter_group_name               = optional(string)
    apply_immediately                     = optional(bool, false)
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
