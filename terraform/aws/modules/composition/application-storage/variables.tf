# Core Infrastructure Variables
variable "environment" {
  description = "Environment name (e.g., dev, integ, prod, sandbox)"
  type        = string

  validation {
    condition     = can(regex("^(dev|integ|prod|sandbox|sbx)$", var.environment))
    error_message = "Environment must be one of: dev, integ, prod, sandbox, sbx."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hyperswitch"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_id" {
  description = "VPC ID where Aurora cluster will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID format (vpc-xxxxxxxx)."
  }
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for Aurora cluster (should be private subnets in different AZs)"
  type        = list(string)

  validation {
    condition     = length(var.database_subnet_ids) >= 2
    error_message = "At least 2 subnet IDs must be provided for Aurora cluster high availability."
  }
}

variable "application_security_group_id" {
  description = "Security group ID of the application that needs to access the database"
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.application_security_group_id))
    error_message = "Application security group ID must be a valid AWS security group ID format (sg-xxxxxxxx)."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Aurora Configuration Variables
variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.engine_version))
    error_message = "Engine version must be in format 'X.Y' (e.g., '15.4')."
  }
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "postgres"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.master_username))
    error_message = "Master username must start with a letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "instance_class_override" {
  description = "Override instance class for all environments (optional)"
  type        = string
  default     = null

  validation {
    condition = var.instance_class_override == null || can(regex("^db\\.[a-z0-9]+\\.[a-z]+$", var.instance_class_override))
    error_message = "Instance class must be a valid RDS instance class format (e.g., db.r6g.large)."
  }
}

# Backup and Maintenance Variables
variable "backup_retention_period" {
  description = "Number of days to retain automated backups (daily snapshots enabled)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"

  validation {
    condition     = can(regex("^[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}$", var.backup_window))
    error_message = "Backup window must be in format 'HH:MM-HH:MM' (e.g., '03:00-04:00')."
  }
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"

  validation {
    condition     = can(regex("^[a-z]{3}:[0-9]{2}:[0-9]{2}-[a-z]{3}:[0-9]{2}:[0-9]{2}$", var.maintenance_window))
    error_message = "Maintenance window must be in format 'ddd:HH:MM-ddd:HH:MM' (e.g., 'sun:04:00-sun:05:00')."
  }
}

# Security Variables
variable "kms_key_id" {
  description = "KMS key ID for encryption (uses default key if not specified)"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection for the Aurora cluster"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting the cluster (only for non-production)"
  type        = bool
  default     = false
}

# Monitoring Variables
variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights for the Aurora cluster"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([7, 731], var.performance_insights_retention_period)
    error_message = "Performance Insights retention period must be 7 or 731 days."
  }
}

# Parameter Group Variables
variable "parameter_group_family" {
  description = "Aurora PostgreSQL parameter group family"
  type        = string
  default     = "aurora-postgresql15"

  validation {
    condition     = can(regex("^aurora-postgresql[0-9]+$", var.parameter_group_family))
    error_message = "Parameter group family must be in format 'aurora-postgresqlX' where X is version number."
  }
}

variable "cluster_parameters" {
  description = "List of Aurora cluster parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]
}

variable "db_parameters" {
  description = "List of DB instance parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    }
  ]
}

# =============================================================================
# RDS PROXY VARIABLES (OPTIONAL)
# =============================================================================

variable "enable_rds_proxy" {
  description = "Enable RDS Proxy for connection pooling and failover"
  type        = bool
  default     = false
}

variable "rds_proxy_subnet_ids" {
  description = "List of subnet IDs for RDS Proxy (if different from database subnets). Uses database_subnet_ids if not specified"
  type        = list(string)
  default     = null

  validation {
    condition = var.rds_proxy_subnet_ids == null || length(var.rds_proxy_subnet_ids) >= 2
    error_message = "At least 2 subnet IDs must be provided for RDS Proxy high availability."
  }
}

variable "rds_proxy_idle_client_timeout" {
  description = "The number of seconds that a connection to the proxy can be inactive before the proxy disconnects it"
  type        = number
  default     = 1800

  validation {
    condition     = var.rds_proxy_idle_client_timeout >= 1 && var.rds_proxy_idle_client_timeout <= 28800
    error_message = "RDS Proxy idle client timeout must be between 1 and 28800 seconds."
  }
}

variable "rds_proxy_max_connections_percent" {
  description = "The maximum size of the connection pool for each target in a target group"
  type        = number
  default     = 100

  validation {
    condition     = var.rds_proxy_max_connections_percent >= 1 && var.rds_proxy_max_connections_percent <= 100
    error_message = "RDS Proxy max connections percent must be between 1 and 100."
  }
}

variable "rds_proxy_max_idle_connections_percent" {
  description = "Controls how actively the proxy closes idle database connections in the connection pool"
  type        = number
  default     = 50

  validation {
    condition     = var.rds_proxy_max_idle_connections_percent >= 0 && var.rds_proxy_max_idle_connections_percent <= 100
    error_message = "RDS Proxy max idle connections percent must be between 0 and 100."
  }
}

variable "rds_proxy_require_tls" {
  description = "A Boolean parameter that specifies whether Transport Layer Security (TLS) encryption is required for connections to the proxy"
  type        = bool
  default     = true
}

variable "rds_proxy_debug_logging" {
  description = "Whether the proxy includes detailed information about SQL statements in its logs"
  type        = bool
  default     = false
}

variable "rds_proxy_connection_borrow_timeout" {
  description = "The number of seconds for a proxy to wait for a connection to become available in the connection pool"
  type        = number
  default     = 120

  validation {
    condition     = var.rds_proxy_connection_borrow_timeout >= 1 && var.rds_proxy_connection_borrow_timeout <= 3600
    error_message = "RDS Proxy connection borrow timeout must be between 1 and 3600 seconds."
  }
}

variable "rds_proxy_session_pinning_filters" {
  description = "Each item in the list represents a class of SQL operations that normally cause all later statements in a session using a proxy to be pinned to the same underlying database connection"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for filter in var.rds_proxy_session_pinning_filters :
      contains(["EXCLUDE_VARIABLE_SETS"], filter)
    ])
    error_message = "Valid session pinning filters are: EXCLUDE_VARIABLE_SETS."
  }
}