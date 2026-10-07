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
  description = "Region for the Redis instance"
  type        = string
}

variable "instance_id" {
  description = "Instance ID. Defaults to '<environment>-<project_name>-redis-<region>'. Classic Memorystore allows 1-40 characters: lowercase letters, digits and hyphens, starting with a letter"
  type        = string
  default     = null

  validation {
    condition     = var.instance_id == null || can(regex("^[a-z]([a-z0-9-]{0,38}[a-z0-9])?$", var.instance_id))
    error_message = "instance_id must be 1-40 characters: lowercase letters, digits and hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "authorized_network" {
  description = "Full resource ID of the VPC the instance is peered into (projects/<project>/global/networks/<name>), e.g. the vpc-network unit's network_id output. Private Service Access must already be set up on it (an allocated range plus the service networking connection), which vpc-network does"
  type        = string
}

variable "reserved_ip_range" {
  description = "NAME of an allocated Private Service Access range to place the instance in (the vpc-network unit's private_service_access_range_name output). null lets the service pick an unused /29 from any allocated range"
  type        = string
  default     = null
}

variable "tier" {
  description = "STANDARD_HA (primary + standby in another zone, automatic and manual failover) or BASIC (single node, no failover - cheapest, for throwaway environments only)"
  type        = string
  default     = "STANDARD_HA"

  validation {
    condition     = contains(["STANDARD_HA", "BASIC"], var.tier)
    error_message = "tier must be STANDARD_HA or BASIC."
  }
}

variable "memory_size_gb" {
  description = "Capacity in GiB (1-300). The capacity tier - and with it network throughput - grows with size (M1 1-4, M2 5-10, M3 11-35 ...), so a larger instance is also a faster one. See https://cloud.google.com/memorystore/docs/redis/instance-tiers-and-sizes"
  type        = number
  default     = 1

  validation {
    condition     = var.memory_size_gb >= 1 && var.memory_size_gb <= 300
    error_message = "memory_size_gb must be between 1 and 300."
  }
}

variable "redis_version" {
  description = "Redis version, e.g. REDIS_6_X, REDIS_7_0, REDIS_7_2. Pinned by default (the registry module's own default is null, which tracks Google's current default and can drift)"
  type        = string
  default     = "REDIS_7_2"
}

variable "location_id" {
  description = "Zone for the primary. null lets Google choose. When set together with alternative_location_id, both nodes are pinned"
  type        = string
  default     = null
}

variable "alternative_location_id" {
  description = "Zone for the standby (STANDARD_HA only). Must differ from location_id, and both must be set together or both left null"
  type        = string
  default     = null

  validation {
    condition     = (var.location_id == null) == (var.alternative_location_id == null) && (var.alternative_location_id == null || var.alternative_location_id != var.location_id)
    error_message = "Set location_id and alternative_location_id together (and to different zones), or leave both null."
  }
}

variable "read_replica_count" {
  description = "Readable replicas ON TOP of the HA standby, 0-5 (STANDARD_HA only). 0 leaves read replicas disabled. Enabling them on an existing instance needs secondary_ip_range, and the standby itself is not readable. NOT the cluster product's per-shard replica_count - that variable no longer exists here"
  type        = number
  default     = 0

  validation {
    condition     = var.read_replica_count >= 0 && var.read_replica_count <= 5 && (var.read_replica_count == 0 || var.tier == "STANDARD_HA")
    error_message = "read_replica_count must be 0-5, and only STANDARD_HA supports read replicas."
  }
}

variable "secondary_ip_range" {
  description = "Extra /28 range for read-replica node placement. Required only when turning read replicas on for an existing instance"
  type        = string
  default     = null
}

variable "auth_enabled" {
  description = "Enable OSS Redis AUTH. Off by default: the application has no Redis AUTH support"
  type        = bool
  default     = false
}

variable "transit_encryption_mode" {
  description = "DISABLED or SERVER_AUTHENTICATION (TLS). DISABLED by default - the registry module defaults to TLS on, but the application connects in plaintext inside the VPC. Immutable after creation"
  type        = string
  default     = "DISABLED"

  validation {
    condition     = contains(["DISABLED", "SERVER_AUTHENTICATION"], var.transit_encryption_mode)
    error_message = "transit_encryption_mode must be DISABLED or SERVER_AUTHENTICATION."
  }
}

variable "redis_configs" {
  description = "Redis parameters, e.g. { maxmemory-policy = \"volatile-lru\" }. Leave empty to inherit Memorystore's defaults"
  type        = map(string)
  default     = {}
}

variable "persistence_config" {
  description = "In-instance persistence: { persistence_mode = \"RDB\", rdb_snapshot_period = \"ONE_HOUR\" | \"SIX_HOURS\" | \"TWELVE_HOURS\" | \"TWENTY_FOUR_HOURS\" }. null leaves persistence off"
  type = object({
    persistence_mode    = string
    rdb_snapshot_period = string
  })
  default = null
}

variable "maintenance_policy" {
  description = "Weekly maintenance window, in UTC. null lets Google pick one"
  type = object({
    description = optional(string)
    day         = string
    start_time = object({
      hours   = number
      minutes = number
      seconds = number
      nanos   = number
    })
  })
  default = null
}

variable "customer_managed_key" {
  description = "CMEK key for at-rest encryption. null uses Google-managed encryption"
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels to apply to the instance"
  type        = map(string)
  default     = {}
}
