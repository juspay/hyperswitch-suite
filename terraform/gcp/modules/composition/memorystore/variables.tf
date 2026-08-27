variable "project_id" {
  description = "GCP project ID where the instance is created"
  type        = string
}

variable "project_name" {
  description = "Project name for labeling and naming resources"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "region" {
  description = "Region for the Memorystore instance"
  type        = string
}

variable "instance_name" {
  description = "Name of the Redis instance. Defaults to '<environment>-<project_name>-redis-<region>'"
  type        = string
  default     = null
}

variable "authorized_network" {
  description = "Self-link/ID of the VPC network the instance is peered to (requires Private Service Access, see composition/vpc-network)"
  type        = string
}

variable "tier" {
  description = "Service tier: BASIC or STANDARD_HA (STANDARD_HA is the closest match to the AWS module's replication-group default)"
  type        = string
  default     = "STANDARD_HA"
}

variable "memory_size_gb" {
  description = "Redis memory size in GB"
  type        = number
  default     = 5
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "REDIS_7_2"
}

variable "replica_count" {
  description = "Number of read replicas (0 disables read replicas). Only supported on STANDARD_HA"
  type        = number
  default     = 0
}

variable "auth_enabled" {
  description = "Whether to enable Redis AUTH"
  type        = bool
  default     = true
}

variable "transit_encryption_mode" {
  description = "Transit encryption mode: SERVER_AUTHENTICATION or DISABLED"
  type        = string
  default     = "SERVER_AUTHENTICATION"
}

variable "redis_configs" {
  description = "Map of Redis configuration parameters (e.g. maxmemory-policy)"
  type        = map(any)
  default     = {}
}

variable "persistence_mode" {
  description = "Persistence mode: RDB or DISABLED. Null leaves persistence unmanaged by this module"
  type        = string
  default     = null
}

variable "rdb_snapshot_period" {
  description = "RDB snapshot period, required when persistence_mode is RDB"
  type        = string
  default     = "TWENTY_FOUR_HOURS"
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
