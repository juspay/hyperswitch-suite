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
  description = "Bare names (not self-links) of the subnet(s), in `region`, to reserve Private Service Connect addresses in for cluster discovery. Memorystore for Valkey requires a dedicated PSC-capable subnet - not the Private Service Access path classic Memorystore for Redis uses"
  type        = list(string)
}

variable "mode" {
  description = "CLUSTER or CLUSTER_DISABLED. Even a single-shard instance should normally use CLUSTER - that's the cluster-protocol-speaking product this module wraps"
  type        = string
  default     = "CLUSTER"
}

variable "shard_count" {
  description = "Number of shards. 1 is a valid, non-sharded 'cluster of one', used for smaller environments"
  type        = number
  default     = 1
}

variable "replica_count" {
  description = "Number of replica nodes per shard (0-5)"
  type        = number
  default     = 1
}

variable "node_type" {
  description = <<-EOT
    Valkey cluster node type; nine are valid. Compare on WRITABLE keyspace rather
    than the headline size, since Memorystore reserves overhead per node:

      SHARED_CORE_NANO  1.12 GB writable / 1.4 GB    ~ cache.t4g.micro
      custom-pico       1.08 GB / 1.25 GB
      custom-micro      2 GB    / 2.5 GB             ~ cache.t4g.small band
      custom-mini       3 GB    / 3.75 GB
      STANDARD_SMALL    5.2 GB  / 6.5 GB             ~ cache.m6g.large (6.38 GiB)
      HIGHMEM_MEDIUM    10.4 GB / 13 GB              ~ cache.m6g.xlarge
      highcpu-medium    10.4 GB / 13 GB
      standard-large    20.8 GB / 26 GB              ~ cache.m6g.2xlarge
      HIGHMEM_XLARGE    46.4 GB / 58 GB              ~ cache.r6g.2xlarge
      highmem-2xlarge   88 GB   / 110 GB             ~ cache.r6g.4xlarge

    STANDARD_SMALL is the row that matters when promoting the AWS prod topology
    (cache.m6g.large) to GCP.
  EOT
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

# Pass-throughs for backups, persistence, maintenance window, engine parameters
# and cross-region replication. Types and defaults are copied verbatim from the
# upstream submodule, so these validate identically and are a no-op against
# already-applied instances.
#
# Known gap: kms_key (CMEK) is not forwarded - the resource supports it, but the
# newest released upstream version (16.1.1) does not expose it.

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

variable "engine_configs" {
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
  description = "In-instance RDB/AOF persistence, paired with automated_backup_config for off-instance backups. Upstream's default of {} leaves the API at DISABLED"
  type = object({
    mode = optional(string)
    rdb_config = optional(object({
      rdb_snapshot_period     = optional(string)
      rdb_snapshot_start_time = optional(string)
    }), null)
    aof_config = optional(object({
      append_fsync = string
    }), null)
  })
  default = {}
}

variable "automated_backup_config" {
  description = "Scheduled off-instance backups. null means no automated backups, which is the API default. retention is a duration string (e.g. \"604800s\" for 7 days); start_time is the UTC hour"
  type = object({
    start_time = string
    retention  = string
  })
  default = null
}

variable "weekly_maintenance_window" {
  description = "Maintenance window, in UTC. null lets Google pick one. At most one window is supported"
  type = list(object({
    day_of_week        = string
    start_time_hour    = optional(string)
    start_time_minutes = optional(string)
    start_time_seconds = optional(string)
    start_time_nanos   = optional(string)
  }))
  default = null
}

variable "maintenance_version" {
  description = "Desired maintenance version, used to trigger a self-service update. An explicit opt-in per upgrade rather than a standing policy. Upgrade-only - downgrades are not supported"
  type        = string
  default     = null
}

variable "instance_role" {
  description = "Cross-region replication role: PRIMARY, SECONDARY, NONE or INSTANCE_ROLE_UNSPECIFIED. null leaves the instance standalone"
  type        = string
  default     = null
}

variable "primary_instance" {
  description = "The instance replicated FROM, set only when instance_role = SECONDARY. Format: projects/{project}/locations/{region}/instances/{instance-id}"
  type        = string
  default     = null
}

variable "secondary_instance" {
  description = "Instances replicating FROM this one, set only when instance_role = PRIMARY. Format: projects/{project}/locations/{region}/instances/{instance-id}."
  type        = list(string)
  default     = []
}

variable "managed_backup_source" {
  description = "Restore the new instance from an existing Memorystore backup. Format: projects/{project}/locations/{location}/backupCollections/{collection}/backups/{backup}. Only honoured at create time"
  type        = string
  default     = null
}

variable "gcs_source" {
  description = "Restore the new instance from RDB file(s) in GCS - comma-separated gs:// URIs, and the practical path for a data migration. Only honoured at create time"
  type        = string
  default     = null
}
