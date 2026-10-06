variable "source_bucket_name" {
  description = "Name of the source bucket (in the default provider's region)."
  type        = string
}

variable "destination_bucket_name" {
  description = "Name of the destination (replica) bucket in the aws.replica region."
  type        = string
}

variable "create_source_bucket" {
  description = "Create the source bucket. Set false to attach replication to an EXISTING source bucket (which must already be versioned)."
  type        = bool
  default     = true
}

variable "create_destination_bucket" {
  description = "Create the destination (replica) bucket. Set false to replicate into an existing bucket referenced by destination_bucket_name (must already be versioned)."
  type        = bool
  default     = true
}

variable "replication_rule_id" {
  description = "Identifier for the replication rule."
  type        = string
  default     = "crr"
}

variable "replication_prefix" {
  description = "Optional key prefix to scope replication to. Null replicates the whole bucket."
  type        = string
  default     = null

  validation {
    condition     = var.replication_prefix == null || !startswith(var.replication_prefix, "/")
    error_message = "replication_prefix must not start with '/'; S3 object keys have no leading slash."
  }
}

variable "replicate_delete_markers" {
  description = "Replicate delete markers from source to destination."
  type        = bool
  default     = false
}

variable "destination_storage_class" {
  description = "Storage class for replicated objects in the destination bucket."
  type        = string
  default     = "STANDARD"
}

variable "replication_role_name" {
  description = "Name of the IAM role S3 uses for replication. Defaults to a name derived from the source bucket."
  type        = string
  default     = null
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm for both buckets (AES256 or aws:kms)."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "sse_algorithm must be either AES256 or aws:kms."
  }
}

variable "source_kms_key_arn" {
  description = "Existing KMS key ARN (source region) for the source bucket when sse_algorithm is aws:kms. Key creation is out of scope for this glue module."
  type        = string
  default     = null
}

variable "destination_kms_key_arn" {
  description = "Existing KMS key ARN (replica region) for the destination bucket + replica encryption when sse_algorithm is aws:kms."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow deletion of non-empty buckets this module creates."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the buckets and the replication role."
  type        = map(string)
  default     = {}
}
