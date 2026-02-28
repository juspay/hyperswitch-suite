# General Variables
variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

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
  description = "List of subnet IDs for ElastiCache"
  type        = list(string)
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ElastiCache Replication Group Variables (Required)
variable "elasticache_replication_group_id" {
  description = "(Optional) Replication group identifier. This parameter is stored as a lowercase string"
  type        = string
  default     = null
}

# Engine Configuration
variable "engine" {
  description = "(Optional) Name of the cache engine to be used. Valid values are redis or valkey"
  type        = string
  default     = "redis"
}

variable "engine_version" {
  description = "(Optional) Version number of the cache engine. For version 7+, use major.minor format (e.g., 7.2)"
  type        = string
  default     = "7.0"
}

variable "parameter_group_name" {
  description = "(Optional) Name of the parameter group to associate with this replication group"
  type        = string
  default     = "default.redis7"
}

variable "port" {
  description = "(Optional) Port number on which each cache node will accept connections. Default is 6379 for Redis"
  type        = number
  default     = 6379
}

# Node Configuration
variable "node_type" {
  description = "(Optional) Instance class to be used. Required unless global_replication_group_id is set"
  type        = string
  default     = "cache.t3.small"
}

variable "num_cache_clusters" {
  description = "(Optional) Number of cache clusters (primary and replicas). Must be at least 2 if automatic_failover_enabled or multi_az_enabled are true. Conflicts with num_node_groups"
  type        = number
  default     = null

  validation {
    condition     = var.num_cache_clusters == null || var.num_cache_clusters >= 1
    error_message = "num_cache_clusters must be at least 1."
  }
}

variable "num_node_groups" {
  description = "(Optional) Number of node groups (shards) for this Redis replication group. Conflicts with num_cache_clusters"
  type        = number
  default     = null
}

variable "replicas_per_node_group" {
  description = "(Optional) Number of replica nodes in each node group. Valid values are 0 to 5. Conflicts with num_cache_clusters. Can only be set if num_node_groups is set"
  type        = number
  default     = null

  validation {
    condition     = var.replicas_per_node_group == null || (var.replicas_per_node_group >= 0 && var.replicas_per_node_group <= 5)
    error_message = "replicas_per_node_group must be between 0 and 5."
  }
}

# Cluster Mode
variable "cluster_mode" {
  description = "(Optional) Specifies whether cluster mode is enabled or disabled. Valid values are enabled, disabled, or compatible"
  type        = string
  default     = "enabled"

  validation {
    condition     = var.cluster_mode == null || contains(["enabled", "disabled", "compatible"], var.cluster_mode)
    error_message = "cluster_mode must be one of: enabled, disabled, compatible."
  }
}

variable "data_tiering_enabled" {
  description = "(Optional) Enables data tiering. Data tiering is only supported for replication groups using the r6gd node type"
  type        = bool
  default     = false
}

# High Availability
variable "automatic_failover_enabled" {
  description = "(Optional) Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "(Optional) Specifies whether to enable Multi-AZ Support. If true, automatic_failover_enabled must also be enabled"
  type        = bool
  default     = true
}

variable "preferred_cache_cluster_azs" {
  description = "(Optional) List of EC2 availability zones in which the replication group's cache clusters will be created. The first item will be the primary node"
  type        = list(string)
  default     = null
}

# Global Replication
variable "create_global_replication_group" {
  description = "Whether to create a global replication group for multi-region deployment (only applies to primary cluster)"
  type        = bool
  default     = false
}

variable "global_replication_group_id" {
  description = "(Optional) The ID of the global replication group to which this replication group should belong. If not provided, will be auto-generated"
  type        = string
  default     = null
}

variable "global_deletion_protection" {
  description = "Whether deletion protection is enabled for the global replication group"
  type        = bool
  default     = true
}

variable "is_secondary_region" {
  description = "Whether this is a secondary region in a global replication setup (attaches to existing global replication group)"
  type        = bool
  default     = false
}

variable "use_existing_as_global_primary" {
  description = "Whether to use existing cluster as primary for global replication group (links existing cluster instead of creating new)"
  type        = bool
  default     = false
}

variable "source_replication_group_id" {
  description = "ARN of existing replication group to use as primary for global replication group (only used when use_existing_as_global_primary is true)"
  type        = string
  default     = null
}

# Security
variable "at_rest_encryption_enabled" {
  description = "(Optional) Whether to enable encryption at rest. When engine is redis, default is false. When engine is valkey, default is true"
  type        = bool
  default     = false
}

variable "transit_encryption_enabled" {
  description = "(Optional) Whether to enable encryption in transit. Changing this with engine_version < 7.0.5 will force replacement"
  type        = bool
  default     = false
}

variable "transit_encryption_mode" {
  description = "(Optional) A setting that enables clients to migrate to in-transit encryption with no downtime. Valid values are preferred and required"
  type        = string
  default     = null

  validation {
    condition     = var.transit_encryption_mode == null || contains(["preferred", "required"], var.transit_encryption_mode)
    error_message = "transit_encryption_mode must be either 'preferred' or 'required'."
  }
}

variable "auth_token" {
  description = "(Optional) Password used to access a password protected server. Can be specified only if transit_encryption_enabled = true"
  type        = string
  default     = null
  sensitive   = true
}

variable "auth_token_update_strategy" {
  description = "(Optional) Strategy to use when updating auth_token. Valid values are SET, ROTATE, and DELETE. If omitted, AWS defaults to ROTATE"
  type        = string
  default     = null

  validation {
    condition     = var.auth_token_update_strategy == null || contains(["SET", "ROTATE", "DELETE"], var.auth_token_update_strategy)
    error_message = "auth_token_update_strategy must be one of: SET, ROTATE, DELETE."
  }
}

variable "kms_key_id" {
  description = "(Optional) The ARN of the key that you wish to use if encrypting at rest. Can be specified only if at_rest_encryption_enabled = true"
  type        = string
  default     = null
}

# Network Configuration
variable "ip_discovery" {
  description = "(Optional) The IP version to advertise in the discovery protocol. Valid values are ipv4 or ipv6"
  type        = string
  default     = "ipv4"

  validation {
    condition     = var.ip_discovery == null || contains(["ipv4", "ipv6"], var.ip_discovery)
    error_message = "ip_discovery must be either 'ipv4' or 'ipv6'."
  }
}

variable "network_type" {
  description = "(Optional) The IP versions for cache cluster connections. Valid values are ipv4, ipv6, or dual_stack"
  type        = string
  default     = "ipv4"

  validation {
    condition     = var.network_type == null || contains(["ipv4", "ipv6", "dual_stack"], var.network_type)
    error_message = "network_type must be one of: ipv4, ipv6, dual_stack."
  }
}

# Maintenance & Backup
variable "maintenance_window" {
  description = "(Optional) Specifies the weekly time range for maintenance. Format: ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). Minimum 60 minute period"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "snapshot_window" {
  description = "(Optional, Redis only) Daily time range (in UTC) during which ElastiCache will begin taking a daily snapshot. Minimum 60 minute period"
  type        = string
  default     = "03:00-05:00"
}

variable "snapshot_retention_limit" {
  description = "(Optional, Redis only) Number of days for which ElastiCache will retain automatic snapshots before deleting them. 0 disables backups"
  type        = number
  default     = 1

  validation {
    condition     = var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35
    error_message = "snapshot_retention_limit must be between 0 and 35."
  }
}

variable "snapshot_arns" {
  description = "(Optional) List of ARNs that identify Redis RDB snapshot files stored in Amazon S3"
  type        = list(string)
  default     = null
}

variable "snapshot_name" {
  description = "(Optional) The name of a snapshot from which to restore data into the new node group"
  type        = string
  default     = null
}

variable "snapshot_arn" {
  description = "(Optional) The ARN of a snapshot from which to restore data into the new node group (for cross-region or cross-account restoration)"
  type        = string
  default     = null
}

variable "final_snapshot_identifier" {
  description = "(Optional) Name of your final node group (shard) snapshot. If omitted, no final snapshot will be made"
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "(Optional) Specifies whether minor version engine upgrades will be applied automatically during the maintenance window. Only for engine types redis/valkey and engine version 6+"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "(Optional) Specifies whether any modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

# Notifications
variable "notification_topic_arn" {
  description = "(Optional) ARN of an SNS topic to send ElastiCache notifications"
  type        = string
  default     = null
}

# User Groups
variable "user_group_ids" {
  description = "(Optional) User Group IDs to associate with the replication group. Maximum of one user group ID"
  type        = set(string)
  default     = null
}

# Log Delivery
variable "log_delivery_configuration" {
  description = "(Optional, Redis only) Specifies the destination and format of Redis/Valkey SLOWLOG or Engine Log. Max of 2 blocks"
  type = list(object({
    destination      = string
    destination_type = string
    log_format       = string
    log_type         = string
  }))
  default = []

  validation {
    condition     = length(var.log_delivery_configuration) <= 2
    error_message = "Maximum of 2 log_delivery_configuration blocks allowed."
  }
}

# Node Group Configuration
variable "node_group_configuration" {
  description = "(Optional) Configuration for node groups (shards). Can be specified only if num_node_groups is set. Conflicts with preferred_cache_cluster_azs"
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

# Subnet Group Variables
variable "create_elasticache_subnet_group" {
  description = "Whether to create an ElastiCache subnet group"
  type        = bool
  default     = true
}

variable "elasticache_subnet_group_name" {
  description = "(Optional) Name of the cache subnet group. Required if create_elasticache_subnet_group is false"
  type        = string
  default     = null
}

# Security Group Variables
variable "create_security_group" {
  description = "Whether to create a security group for ElastiCache"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "(Optional) Name of the security group for ElastiCache"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "(Optional) Description for the security group."
  type        = string
  default     = null
}

variable "existing_security_group_ids" {
  description = "(Optional) List of existing security group IDs to attach to ElastiCache"
  type        = list(string)
  default     = []
}
