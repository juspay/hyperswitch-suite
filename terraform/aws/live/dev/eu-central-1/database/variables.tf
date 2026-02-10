# ============================================================================
# Environment Variables
# ============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
  default     = null # Will be fetched from remote state
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS DB subnet group"
  type        = list(string)
}

# ============================================================================
# RDS Cluster Configuration
# ============================================================================

variable "cluster_identifier" {
  description = "The cluster identifier"
  type        = string
  default     = "hyperswitchdb-cluster"
}

variable "engine" {
  description = "Database engine"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "13.20"
}

variable "engine_mode" {
  description = "Database engine mode"
  type        = string
  default     = "provisioned"
}

variable "engine_lifecycle_support" {
  description = "The life cycle type for this DB instance"
  type        = string
  default     = "open-source-rds-extended-support"
}

# Database Configuration
variable "database_name" {
  description = "Name for the database"
  type        = string
  default     = null
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
  default     = null # Should be provided via terraform.tfvars or environment variable
}

# Multi-AZ Configuration
variable "availability_zones" {
  description = "List of EC2 Availability Zones"
  type        = list(string)
  default     = null
}

variable "allocated_storage" {
  description = "Allocated storage in GiB"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type"
  type        = string
  default     = "aurora-iopt1"
}

variable "iops" {
  description = "Amount of Provisioned IOPS"
  type        = number
  default     = 0
}

# Network Configuration
variable "network_type" {
  description = "Network type of the cluster"
  type        = string
  default     = "IPV4"
}

variable "port" {
  description = "Port on which the DB accepts connections"
  type        = number
  default     = 5432
}

variable "create_db_subnet_group" {
  description = "Whether to create a new DB subnet group"
  type        = bool
  default     = true
}

variable "db_subnet_group_name" {
  description = "DB subnet group name"
  type        = string
  default     = null
}

# Parameter Groups
variable "db_cluster_parameter_group_name" {
  description = "A cluster parameter group to associate with the cluster"
  type        = string
  default     = "default.aurora-postgresql13"
}

variable "db_instance_parameter_group_name" {
  description = "Instance parameter group to associate with all instances"
  type        = string
  default     = null
}

# ============================================================================
# Backup and Maintenance Configuration
# ============================================================================

variable "backup_retention_period" {
  description = "Days to retain backups"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Daily time range during which automated backups are created"
  type        = string
  default     = null
}

variable "preferred_maintenance_window" {
  description = "Weekly time range during which system maintenance can occur"
  type        = string
  default     = null
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created"
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "Name of the final DB snapshot"
  type        = string
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Copy all cluster tags to snapshots"
  type        = bool
  default     = false
}

# ============================================================================
# Security and Encryption Configuration
# ============================================================================

variable "storage_encrypted" {
  description = "Specifies whether the DB cluster is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "ARN for the KMS encryption key"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "If the DB cluster should have deletion protection enabled"
  type        = bool
  default     = false
}

variable "delete_automated_backups" {
  description = "Specifies whether to remove automated backups immediately"
  type        = bool
  default     = true
}

# ============================================================================
# Monitoring Configuration
# ============================================================================

variable "enabled_cloudwatch_logs_exports" {
  description = "Set of log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql"]
}

variable "performance_insights_enabled" {
  description = "Enables Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "KMS Key ID to encrypt Performance Insights data"
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "Amount of time to retain performance insights data"
  type        = number
  default     = 0
}

variable "monitoring_interval" {
  description = "Interval for Enhanced Monitoring metrics"
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "ARN for the IAM role for enhanced monitoring"
  type        = string
  default     = null
}

variable "database_insights_mode" {
  description = "The mode of Database Insights"
  type        = string
  default     = "standard"
}

# ============================================================================
# HTTP Endpoint Configuration
# ============================================================================

variable "enable_http_endpoint" {
  description = "Enable HTTP endpoint (data API)"
  type        = bool
  default     = false
}

# ============================================================================
# Backtrack Configuration
# ============================================================================

variable "backtrack_window" {
  description = "Target backtrack window, in seconds"
  type        = number
  default     = 0
}

# ============================================================================
# Security Group Configuration
# ============================================================================

variable "create_security_group" {
  description = "Whether to create a new security group"
  type        = bool
  default     = false
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
  default     = []
}

variable "security_group_name" {
  description = "Name for the security group"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description for the security group"
  type        = string
  default     = null
}

# ============================================================================
# Cluster Instances Configuration
# ============================================================================

variable "cluster_instances" {
  description = "Map of cluster instances to create"
  type = map(object({
    identifier                            = optional(string)
    identifier_prefix                     = optional(string)
    instance_class                        = string
    engine                                = optional(string)
    engine_version                        = optional(string)
    publicly_accessible                   = optional(bool, false)
    db_subnet_group_name                  = optional(string)
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

# ============================================================================
# Tags
# ============================================================================

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
