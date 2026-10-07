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
    - rule_id:       ID for the replication rule.
  EOT
  type = object({
    enabled       = optional(bool, false)
    region        = optional(string)
    bucket_name   = optional(string)
    storage_class = optional(string, "STANDARD")
    kms_key_arn   = optional(string)
    rule_id       = optional(string, "replicate-all")
  })
  default = {}
}
