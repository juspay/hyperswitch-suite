variable "create" {
  type    = bool
  default = true
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  type    = string
  default = "hyperswitch"
}

variable "bucket_name" {
  description = "S3 bucket name for CloudFront logs (default: {project}-cf-logs-{region}-{env})"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Allow destruction of non-empty bucket"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  type    = bool
  default = false
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for log objects"
  type = list(object({
    id                                     = string
    enabled                                = optional(bool, true)
    prefix                                 = optional(string, "")
    transition_to_ia_days                  = optional(number, 30)
    transition_to_glacier_days             = optional(number, 90)
    expiration_days                        = optional(number, 365)
    noncurrent_version_transition_ia_days  = optional(number, 30)
    noncurrent_version_transition_glacier_days = optional(number, 90)
    noncurrent_version_expiration_days     = optional(number, 365)
  }))
  default = [
    {
      id                          = "logs-lifecycle"
      enabled                     = true
      prefix                      = ""
      transition_to_ia_days       = 30
      transition_to_glacier_days  = 90
      expiration_days             = 365
      noncurrent_version_transition_ia_days  = 30
      noncurrent_version_transition_glacier_days = 90
      noncurrent_version_expiration_days     = 365
    }
  ]
}

variable "block_public_access" {
  type    = bool
  default = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm (AES256 or aws:kms)"
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "KMS key ID for SSE-KMS (leave empty for AES256)"
  type        = string
  default     = null
}

variable "enable_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_target_bucket_arn" {
  description = "ARN of replication target bucket"
  type        = string
  default     = null
}

variable "replication_role_arn" {
  description = "IAM role ARN for replication"
  type        = string
  default     = null
}

variable "replication_storage_class" {
  description = "Storage class for replicated objects"
  type        = string
  default     = "STANDARD_IA"
}

variable "tags" {
  type    = map(string)
  default = {}
}
