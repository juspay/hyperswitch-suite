variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "display_name" {
  description = "Equivalent to AWS replication_group_id"
  type        = string
  default     = null
}

variable "software_version" {
  description = "Redis version, e.g. \"7.2\" (equivalent to AWS engine_version)"
  type        = string
  default     = "7.2"
}

variable "node_count" {
  description = "Number of nodes (equivalent to AWS num_cache_clusters)"
  type        = number
  default     = 3
}

variable "node_memory_in_gbs" {
  description = "Memory per node in GB (equivalent to AWS node_type sizing)"
  type        = number
  default     = 8
}

variable "cluster_mode" {
  description = "SHARDED or NONSHARDED (equivalent to AWS cluster_mode enabled/disabled)"
  type        = string
  default     = "NONSHARDED"
}

variable "shard_count" {
  description = "Only used when cluster_mode = SHARDED (equivalent to AWS num_node_groups)"
  type        = number
  default     = null
}

variable "subnet_id" {
  description = "Equivalent to AWS elasticache_subnet_group_name / subnet_ids"
  type        = string
}

variable "nsg_ids" {
  description = "Equivalent to AWS security_group_ids"
  type        = list(string)
  default     = []
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
