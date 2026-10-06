variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "force_destroy" {
  description = "Whether to allow bucket deletion with objects in it"
  type        = bool
  default     = false
}

variable "create_bucket" {
  description = "Whether to create the bucket. Set false to manage replication on a pre-existing bucket (which must already be versioned) without creating/managing the bucket itself."
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = false
}

variable "versioning_status" {
  description = "Versioning status (Enabled, Suspended, Disabled)"
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Suspended", "Disabled"], var.versioning_status)
    error_message = "Versioning status must be one of: Enabled, Suspended, Disabled"
  }
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm (AES256 or aws:kms)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "SSE algorithm must be either AES256 or aws:kms"
  }
}

variable "kms_master_key_id" {
  description = "KMS key ID for encryption (required if sse_algorithm is aws:kms)"
  type        = string
  default     = null
}

variable "block_public_acls" {
  description = "Block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules"
  type = list(object({
    id                            = string
    enabled                       = bool
    prefix                        = optional(string, "")
    expiration_days               = optional(number, null)
    noncurrent_version_expiration = optional(number, null)
    transition = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default = []
}

variable "enable_replication" {
  description = "Enable S3 replication configuration on this (source) bucket. Requires versioning to be enabled."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_replication || var.replication_role_arn != null || var.create_replication_role
    error_message = "set replication_role_arn (or create_replication_role = true) when enable_replication is true"
  }

  validation {
    condition     = !var.enable_replication || var.enable_versioning || !var.create_bucket
    error_message = "enable_versioning must be true when enable_replication is true on a created bucket (S3 replication requires versioning)"
  }

  validation {
    condition     = !var.enable_replication || length(var.replication_rules) > 0
    error_message = "replication_rules must contain at least one rule when enable_replication is true"
  }
}

variable "replication_role_arn" {
  description = "ARN of an existing IAM role S3 assumes to replicate objects. Required when enable_replication is true and create_replication_role is false."
  type        = string
  default     = null
}

variable "create_replication_role" {
  description = "Create the IAM role S3 assumes to replicate FROM this bucket, derived from replication_rules (source = this bucket, destinations = the rules' buckets, object perms scoped to each rule's prefix). When false, pass replication_role_arn."
  type        = bool
  default     = false
}

variable "replication_role_name" {
  description = "Name for the replication role when create_replication_role = true. Defaults to s3-crr-<bucket_name>."
  type        = string
  default     = null
}

variable "replication_rules" {
  description = "List of replication rules applied when enable_replication is true."
  type = list(object({
    id                        = string
    status                    = optional(string, "Enabled")
    priority                  = optional(number, 0)
    prefix                    = optional(string, null)
    destination_bucket_arn    = string
    destination_storage_class = optional(string, "STANDARD")
    replica_kms_key_id        = optional(string, null) # when set, replicates SSE-KMS encrypted objects to this key
    delete_marker_replication = optional(bool, false)
  }))
  default = []
}

variable "tags" {
  description = "Map of tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
