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
variable "source_bucket_name" {
  description = "Name of the source S3 bucket to create"
  type        = string
}

variable "force_destroy" {
  description = "Allow deleting non-empty buckets on destroy (applies to both source and replica)"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning on the source bucket. Forced to true when enable_replication is true, since cross-region replication requires versioning."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for SSE-KMS on the buckets. When null, SSE-S3 (AES256) is used."
  type        = string
  default     = null
}

# Replication
variable "enable_replication" {
  description = "Whether to create a replica bucket in a different region and configure cross-region replication from the source bucket."
  type        = bool
  default     = false
}

variable "replica_region" {
  description = "Region for the replica bucket. Required when enable_replication is true."
  type        = string
  default     = null
}

variable "replica_bucket_name" {
  description = "Name of the replica S3 bucket. Required when enable_replication is true."
  type        = string
  default     = null
}

variable "replica_storage_class" {
  description = "Storage class for replicated objects in the replica bucket"
  type        = string
  default     = "STANDARD"
}

variable "replication_rule_id" {
  description = "ID for the replication rule"
  type        = string
  default     = "replicate-all"
}
