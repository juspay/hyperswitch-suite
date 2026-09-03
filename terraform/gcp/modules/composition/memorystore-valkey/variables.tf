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
  description = <<-EOT
    Valkey cluster node type. Nine are valid, not the four originally listed here
    (corrected 2026-09-02) - the variable carries no validation, so the others
    already worked. Compare on WRITABLE keyspace, not the headline size, because
    Memorystore reserves overhead per node:

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

# ============================================================================
# Pass-throughs added 2026-09-02 after an AWS-vs-GCP parity audit (see
# hyperswitch-infra docs/aws-to-gcp/memorystore-valkey-vs-elasticache.md).
# Every one of these already exists on the upstream registry submodule
# (terraform-google-modules/memorystore/google//modules/valkey v16.1.1) - the
# wrapper simply never forwarded them, so there was no way to set backups,
# persistence, a maintenance window, engine parameters or cross-region
# replication from the live layer at all. Types are copied verbatim from
# upstream so validation behaves identically.
#
# Defaults are deliberately upstream's own defaults, so adding these is a
# no-op against already-applied instances - verified against the live dev
# instance on 2026-09-02 (`gcloud memorystore instances list
# --location=asia-south1 --project=hyperswitch-dev`), which reports
# persistenceConfig.mode=DISABLED, automatedBackupConfig.automatedBackupMode=
# DISABLED, no maintenancePolicy, and zoneDistributionConfig.mode=MULTI_ZONE.
#
# NOT added: kms_key (CMEK). The google_memorystore_instance resource supports
# it and upstream carries it on master, but the newest RELEASED version is
# 16.1.1, which does not expose it. Revisit when 16.2.x ships - AWS sets
# kms_key_id on prod us-east-1 and the locker cluster, so this is a real
# remaining gap, not a decision.
# ============================================================================

variable "zone_distribution_config_mode" {
  description = "Zone distribution for the cluster (Immutable). MULTI_ZONE is the analogue of AWS ElastiCache's multi_az_enabled=true and is the default; SINGLE_ZONE is only for deliberately cheap non-HA environments. Changing this on a live instance forces replacement."
  type        = string
  default     = "MULTI_ZONE"
}

variable "zone_distribution_config_zone" {
  description = "The zone for a SINGLE_ZONE cluster (Immutable). Ignored unless zone_distribution_config_mode is SINGLE_ZONE."
  type        = string
  default     = null
}

variable "engine_configs" {
  description = "Engine parameters - the analogue of AWS ElastiCache's parameter_group_name, except set inline rather than as a separate parameter-group resource. Leave null to inherit Memorystore's defaults, which already match AWS's default.valkey8 group on the parameter that matters most (maxmemory-policy defaults to volatile-lru on both)."
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
  description = "RDB/AOF persistence. ElastiCache has no separate persistence knob - its snapshots serve both roles - so on GCP this pairs with automated_backup_config to reach parity. Upstream's default of {} leaves the API at DISABLED."
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
  description = "Scheduled backups - the direct analogue of AWS ElastiCache's snapshot_window + snapshot_retention_limit. null means NO automated backups, which is the API default. retention is a duration string (e.g. \"604800s\" for 7 days, matching the AWS units' snapshot_retention_limit = 7); start_time is the UTC hour."
  type = object({
    start_time = string
    retention  = string
  })
  default = null
}

variable "weekly_maintenance_window" {
  description = "Maintenance window - the analogue of AWS ElastiCache's maintenance_window (\"mon:04:00-mon:05:00\"). Times are UTC on both clouds, so AWS windows translate directly. null lets Google pick the window for you. At most one window is supported."
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
  description = "Desired maintenance version, used to trigger a self-service update. Loosely the analogue of AWS's auto_minor_version_upgrade/apply_immediately pair, except it is an explicit opt-in per upgrade rather than a standing policy. Upgrade-only - downgrades are not supported."
  type        = string
  default     = null
}

variable "instance_role" {
  description = "Cross-region replication role: PRIMARY, SECONDARY, NONE or INSTANCE_ROLE_UNSPECIFIED. This is the GCP analogue of AWS's global replication group - see the is_passive/create_global_replication_group pattern on the AWS elasticache catalog unit. null leaves the instance standalone."
  type        = string
  default     = null
}

variable "primary_instance" {
  description = "The instance replicated FROM, set only when instance_role = SECONDARY. Format: projects/{project}/locations/{region}/instances/{instance-id}. Analogous to AWS's global_replication_group_id on a secondary-region replication group."
  type        = string
  default     = null
}

variable "secondary_instance" {
  description = "Instances replicating FROM this one, set only when instance_role = PRIMARY. Format: projects/{project}/locations/{region}/instances/{instance-id}."
  type        = list(string)
  default     = []
}

variable "managed_backup_source" {
  description = "Restore the new instance from an existing Memorystore backup - the analogue of AWS's snapshot_name. Format: projects/{project}/locations/{location}/backupCollections/{collection}/backups/{backup}. Only honoured at create time."
  type        = string
  default     = null
}

variable "gcs_source" {
  description = "Restore the new instance from RDB file(s) in GCS - the analogue of AWS's snapshot_arns, and the practical path for an ElastiCache-to-Memorystore data migration. Comma-separated gs:// URIs. Only honoured at create time."
  type        = string
  default     = null
}
