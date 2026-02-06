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
  description = "VPC ID where ElastiCache will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ElastiCache subnet group"
  type        = list(string)
}

# ============================================================================
# ElastiCache Replication Group Configuration
# ============================================================================

variable "elasticache_replication_group_id" {
  description = "Replication group identifier"
  type        = string
  default     = null
}

# Engine Configuration
variable "engine" {
  description = "Cache engine (redis or valkey)"
  type        = string
  default     = "redis"
}

variable "engine_version" {
  description = "Cache engine version"
  type        = string
  default     = "7.0"
}

variable "parameter_group_name" {
  description = "Parameter group name"
  type        = string
  default     = "default.redis7"
}

variable "port" {
  description = "Port number for cache connections"
  type        = number
  default     = 6379
}

# Node Configuration
variable "node_type" {
  description = "Instance class for cache nodes"
  type        = string
  default     = "cache.t3.small"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (primary and replicas)"
  type        = number
  default     = 2
}

variable "num_node_groups" {
  description = "Number of node groups (shards) for cluster mode"
  type        = number
  default     = null
}

variable "replicas_per_node_group" {
  description = "Number of replica nodes per node group"
  type        = number
  default     = null
}

# Cluster Mode
variable "cluster_mode" {
  description = "Cluster mode: enabled, disabled, or compatible"
  type        = string
  default     = "disabled"
}

variable "data_tiering_enabled" {
  description = "Enable data tiering (r6gd nodes only)"
  type        = bool
  default     = false
}

# High Availability
variable "automatic_failover_enabled" {
  description = "Enable automatic failover"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "preferred_cache_cluster_azs" {
  description = "List of availability zones for cache clusters"
  type        = list(string)
  default     = null
}

# Global Replication
variable "global_replication_group_id" {
  description = "Global replication group ID"
  type        = string
  default     = null
}

# Security
variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = false
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in transit"
  type        = bool
  default     = false
}

variable "transit_encryption_mode" {
  description = "Transit encryption mode: preferred or required"
  type        = string
  default     = null
}

variable "auth_token" {
  description = "Password for Redis AUTH"
  type        = string
  default     = null
  sensitive   = true
}

variable "auth_token_update_strategy" {
  description = "Strategy for auth token updates: SET, ROTATE, DELETE"
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption at rest"
  type        = string
  default     = null
}

# Network Configuration
variable "ip_discovery" {
  description = "IP discovery mode: ipv4 or ipv6"
  type        = string
  default     = "ipv4"
}

variable "network_type" {
  description = "Network type: ipv4, ipv6, or dual_stack"
  type        = string
  default     = "ipv4"
}

# Maintenance & Backup
variable "maintenance_window" {
  description = "Weekly maintenance window"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "snapshot_window" {
  description = "Daily snapshot window"
  type        = string
  default     = "03:00-05:00"
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain snapshots"
  type        = number
  default     = 7
}

variable "snapshot_arns" {
  description = "S3 ARNs of Redis RDB snapshot files"
  type        = list(string)
  default     = null
}

variable "snapshot_name" {
  description = "Snapshot name to restore from"
  type        = string
  default     = null
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier before deletion"
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

# Notifications
variable "notification_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
  default     = null
}

# User Groups
variable "user_group_ids" {
  description = "User group IDs to associate"
  type        = set(string)
  default     = null
}

# Log Delivery
variable "log_delivery_configuration" {
  description = "Log delivery configuration for SLOWLOG or Engine Log"
  type = list(object({
    destination      = string
    destination_type = string
    log_format       = string
    log_type         = string
  }))
  default = []
}

# Node Group Configuration
variable "node_group_configuration" {
  description = "Configuration for node groups (shards)"
  type = list(object({
    node_group_id              = optional(string)
    primary_availability_zone  = optional(string)
    primary_outpost_arn        = optional(string)
    replica_availability_zones = optional(list(string))
    replica_count              = optional(number)
    replica_outpost_arns       = optional(list(string))
    slots                      = optional(string)
  }))
  default = []
}

# Subnet Group
variable "create_elasticache_subnet_group" {
  description = "Create ElastiCache subnet group"
  type        = bool
  default     = true
}

variable "elasticache_subnet_group_name" {
  description = "Existing subnet group name"
  type        = string
  default     = null
}

# Security Group
variable "create_security_group" {
  description = "Create security group for ElastiCache"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Security group name"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description for the security group"
  type        = string
  default     = null
}

variable "existing_security_group_ids" {
  description = "Existing security group IDs"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Service   = "ElastiCache"
  }
}
