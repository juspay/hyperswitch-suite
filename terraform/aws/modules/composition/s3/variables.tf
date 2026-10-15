# General Variables
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
  description = "Primary (source) region. The source bucket is created with the default aws provider, which must be configured for this region."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Source Bucket
variable "bucket_name" {
  description = "Name of the source S3 bucket. When null, it is derived as \"<project_name>-<environment>-<region>\"."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow deleting non-empty buckets on destroy (applies to both source and replica)"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning on the source bucket. Forced to true when replication is enabled, since cross-region replication requires versioning."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN (in the source region) for SSE-KMS on the source bucket. When null, SSE-S3 (AES256) is used."
  type        = string
  default     = null
}

# Replication
variable "replication_configuration" {
  description = <<-EOT
    Cross-region replication configuration. When enabled, a replica bucket is
    created in `region` and CRR is configured from the source bucket.

    - enabled:       whether to create the replica and configure replication.
    - region:        replica region. Required when enabled; must differ from the source region.
    - bucket_name:   replica bucket name. When null, derived as "<project_name>-<environment>-<region>".
    - storage_class: storage class for replicated objects.
    - kms_key_arn:   KMS key ARN in the replica region. Required when the source bucket uses kms_key_arn (KMS keys are regional).
    - rule_id:       ID for the (source -> replica) replication rule.

    Bi-directional (two-way) replication — opt-in, default off:
    - bidirectional:         when true, the replica bucket also replicates back to
                             the source (replica -> source), making the two buckets
                             a mirrored pair. Requires `enabled = true`. S3 prevents
                             infinite replication loops natively; `replica_modifications`
                             is enabled on both rules so metadata changes sync both ways.
                             NOTE: conflict resolution is last-writer-wins (timestamp),
                             so this is for active/passive-with-failback, NOT concurrent
                             multi-region writes to the same key. Existing objects are
                             not back-filled (use S3 Batch Replication). When KMS is
                             used, both source and replica keys must be set (symmetric).
    - reverse_rule_id:       ID for the reverse (replica -> source) rule. Must differ
                             from `rule_id`. Only used when bidirectional = true.
    - reverse_storage_class: storage class for objects replicated back to the source.
  EOT
  type = object({
    enabled       = optional(bool, false)
    region        = optional(string)
    bucket_name   = optional(string)
    storage_class = optional(string, "STANDARD")
    kms_key_arn   = optional(string)
    rule_id       = optional(string, "replicate-all")

    bidirectional         = optional(bool, false)
    reverse_rule_id       = optional(string, "replicate-all-reverse")
    reverse_storage_class = optional(string, "STANDARD")
  })
  default = {}
}
