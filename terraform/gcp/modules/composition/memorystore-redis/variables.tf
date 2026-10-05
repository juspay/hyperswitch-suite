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
  description = "Region for the Redis cluster instance"
  type        = string
}

variable "instance_id" {
  description = "Resource ID of the Redis cluster instance. Defaults to '<environment>-<project_name>-redis-<region>'"
  type        = string
  default     = null
}

variable "network" {
  description = "Bare name (not self-link/ID) of the VPC network to serve discovery/cluster traffic on - this module builds the full projects/.../global/networks/<name> path itself"
  type        = string
}

variable "network_project" {
  description = "Project ID that owns the network, only needed for Shared VPC where the network lives in a different project than project_id"
  type        = string
  default     = null
}

variable "subnet_names" {
  description = "Bare names (not self-links) of the subnet(s), in `region`, to reserve Private Service Connect addresses in for cluster discovery. Memorystore for Redis Cluster requires a dedicated PSC-capable subnet - not the Private Service Access path classic Memorystore for Redis uses"
  type        = list(string)
}

variable "shard_count" {
  description = "Number of shards. 1 is a valid, non-sharded 'cluster of one', used for smaller environments"
  type        = number
  default     = 1
}

variable "replica_count" {
  description = "Number of replica nodes per shard (0-2 - narrower than Valkey's 0-5 on this resource)"
  type        = number
  default     = 0
}

variable "node_type" {
  description = <<-EOT
    Redis Cluster node type - four are valid:

      REDIS_SHARED_CORE_NANO
      REDIS_STANDARD_SMALL
      REDIS_HIGHMEM_MEDIUM
      REDIS_HIGHMEM_XLARGE

    See https://cloud.google.com/memorystore/docs/cluster/node-specification
    for current per-type vCPU/memory figures - not repeated here since they
    change independently of this module. Defaults to the cheapest tier
    (matching memorystore-valkey's own default convention) rather than the
    upstream submodule's default of null, which the API resolves to the much
    larger REDIS_HIGHMEM_MEDIUM - pass null explicitly to get that instead.
  EOT
  type        = string
  default     = "REDIS_SHARED_CORE_NANO"
}

variable "authorization_mode" {
  description = "AUTH_MODE_DISABLED or AUTH_MODE_IAM_AUTH. No plain-password AUTH option exists on this product (unlike classic Memorystore for Redis's auth_string) - IAM auth is the only authenticated mode available"
  type        = string
  default     = "AUTH_MODE_DISABLED"
}

variable "transit_encryption_mode" {
  description = "TRANSIT_ENCRYPTION_MODE_DISABLED or TRANSIT_ENCRYPTION_MODE_SERVER_AUTHENTICATION"
  type        = string
  default     = "TRANSIT_ENCRYPTION_MODE_DISABLED"
}

variable "deletion_protection_enabled" {
  description = "If true, deletion of the instance fails until this is set false first"
  type        = bool
  default     = true
}

variable "kms_key" {
  description = "CMEK key used to encrypt the cluster's at-rest data. null uses Google-managed encryption. Unlike memorystore-valkey (whose installed submodule version doesn't expose this), this resource forwards it directly"
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# Pass-throughs for persistence, maintenance window, engine parameters and
# cross-cluster replication. Types and defaults are copied verbatim from the
# upstream submodule, so these validate identically and are a no-op against
# already-applied instances.
#
# Known gap vs. memorystore-valkey: no automated_backup_config,
# managed_backup_source, or gcs_source - the installed submodule version
# (16.1.1) doesn't expose scheduled off-instance backups or create-time
# restore for this resource yet.

variable "zone_distribution_config_mode" {
  description = "Zone distribution for the cluster. MULTI_ZONE (the default) spreads across zones; SINGLE_ZONE is only for deliberately cheap non-HA environments. Immutable - changing it on a live instance forces replacement"
  type        = string
  default     = "MULTI_ZONE"
}

variable "zone_distribution_config_zone" {
  description = "The zone for a SINGLE_ZONE cluster (Immutable). Ignored unless zone_distribution_config_mode is SINGLE_ZONE."
  type        = string
  default     = null
}

variable "redis_configs" {
  description = "Engine parameters, set inline rather than as a separate parameter-group resource. Leave null to inherit Memorystore's defaults"
  type = object({
    maxmemory               = optional(string)
    maxmemory-clients       = optional(string)
    maxmemory-policy        = optional(string)
    notify-keyspace-events  = optional(string)
    slowlog-log-slower-than = optional(number)
    maxclients              = optional(number)
  })
  default = null
}

variable "persistence_config" {
  description = "In-instance RDB/AOF persistence. There is no automated_backup_config pairing on this resource (see the module-level known-gap note above) - this is the only durability knob available. null leaves the API at its default (PERSISTENCE_MODE_UNSPECIFIED)"
  type = object({
    mode = optional(string)
    rdb_config = optional(object({
      rdb_snapshot_period     = optional(string)
      rdb_snapshot_start_time = optional(string)
    }), null)
    aof_config = optional(object({
      append_fsync = optional(string)
    }), null)
  })
  default = null
}

variable "weekly_maintenance_window" {
  description = "Maintenance window, in UTC. null lets Google pick one. Unlike memorystore-valkey's list(object(...)) (a historical artifact of that submodule's own interface), this resource's underlying submodule takes a single object directly - field names also differ (day_of_the_week/hours/minutes/seconds/nanos here, vs. day_of_week/start_time_hour/etc. there)"
  type = object({
    day_of_the_week = optional(string)
    hours           = optional(string)
    minutes         = optional(string)
    seconds         = optional(string)
    nanos           = optional(number)
  })
  default = null
}

variable "cluster_role" {
  description = "Cross-cluster replication role: NONE, PRIMARY or SECONDARY. null leaves the cluster standalone. This resource's equivalent of memorystore-valkey's instance_role (which also allows INSTANCE_ROLE_UNSPECIFIED - not a valid value here)"
  type        = string
  default     = null
}

variable "primary_cluster" {
  description = "The cluster replicated FROM, set only when cluster_role = SECONDARY. Format: projects/{project}/locations/{region}/clusters/{cluster-id}"
  type        = string
  default     = null
}

variable "secondary_clusters" {
  description = "Clusters replicating FROM this one, set only when cluster_role = PRIMARY. Format: projects/{project}/locations/{region}/clusters/{cluster-id}"
  type        = list(string)
  default     = []
}
