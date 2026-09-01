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
  description = "Region for the Valkey cluster instance"
  type        = string
}

variable "instance_id" {
  description = "Resource ID of the Valkey cluster instance. Defaults to '<environment>-<project_name>-valkey-<region>'"
  type        = string
  default     = null
}

variable "network" {
  description = "Bare name (not self-link/ID) of the VPC network to serve discovery/cluster traffic on - the underlying registry module builds the full projects/.../global/networks/<name> path itself"
  type        = string
}

variable "network_project" {
  description = "Project ID that owns the network, only needed for Shared VPC where the network lives in a different project than project_id"
  type        = string
  default     = null
}

variable "subnet_names" {
  description = "Bare names (not self-links) of the subnet(s), in `region`, to reserve Private Service Connect addresses in for cluster discovery. Memorystore for Valkey requires a dedicated PSC-capable subnet - this is NOT the same private-network path classic Memorystore-for-Redis/PSA uses."
  type        = list(string)
}

variable "mode" {
  description = "CLUSTER or CLUSTER_DISABLED. Even a single-shard instance should normally use CLUSTER - that's the cluster-protocol-speaking product this module wraps"
  type        = string
  default     = "CLUSTER"
}

variable "shard_count" {
  description = "Number of shards. 1 is a valid, non-sharded 'cluster of one' - matches AWS ElastiCache's cluster_mode=enabled with num_node_groups=1 pattern used for smaller environments"
  type        = number
  default     = 1
}

variable "replica_count" {
  description = "Number of replica nodes per shard (0-5)"
  type        = number
  default     = 1
}

variable "node_type" {
  description = "Valkey cluster node type: SHARED_CORE_NANO, STANDARD_SMALL, HIGHMEM_MEDIUM, or HIGHMEM_XLARGE"
  type        = string
  default     = "SHARED_CORE_NANO"
}

variable "engine_version" {
  description = "Valkey engine version"
  type        = string
  default     = "VALKEY_8_0"
}

variable "authorization_mode" {
  description = "AUTH_DISABLED or IAM_AUTH. No plain-password AUTH option exists on this product (unlike classic Memorystore for Redis's auth_string) - IAM_AUTH is the only authenticated mode available"
  type        = string
  default     = "AUTH_DISABLED"
}

variable "transit_encryption_mode" {
  description = "TRANSIT_ENCRYPTION_DISABLED or SERVER_AUTHENTICATION"
  type        = string
  default     = "TRANSIT_ENCRYPTION_DISABLED"
}

variable "deletion_protection_enabled" {
  description = "If true, deletion of the instance fails until this is set false first"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
