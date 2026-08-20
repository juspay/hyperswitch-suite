variable "environment" {
  description = "Environment short name (e.g. prd, sbx)"
  type        = string
}

variable "region" {
  description = "AWS region (kept for parity with sibling modules; not used by the correlator resources themselves)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ElastiCache cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ElastiCache subnet group"
  type        = list(string)
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "engine_version" {
  description = "Valkey engine version"
  type        = string
  default     = "8.2"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the replication group"
  type        = number
  default     = 1

  validation {
    condition     = var.num_cache_clusters >= 1
    error_message = "num_cache_clusters must be at least 1."
  }
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots (0 disables backups)"
  type        = number
  default     = 7

  validation {
    condition     = var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35
    error_message = "snapshot_retention_limit must be between 0 and 35."
  }
}

variable "maintenance_window" {
  description = "Weekly maintenance window (ddd:hh24:mi-ddd:hh24:mi)"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "snapshot_window" {
  description = "Daily snapshot window (hh24:mi-hh24:mi)"
  type        = string
  default     = "23:30-00:30"
}

variable "apply_immediately" {
  description = "Apply cluster changes immediately rather than during the next maintenance window"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources. Overrides the module's defaults on key conflicts."
  type        = map(string)
  default     = {}
}
