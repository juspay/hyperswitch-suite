variable "environment" {
  description = "Environment short name (e.g. prd, sbx)"
  type        = string
}

variable "region" {
  description = "AWS region"
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
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
