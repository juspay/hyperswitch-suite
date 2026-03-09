variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "hs"
}

variable "role_name" {
  description = "Custom IAM role name"
  type        = string
  default     = null
}

variable "oidc_provider_arn" {
  description = "Full OIDC provider ARN from EKS cluster"
  type        = string
}

# ============================================================================
# S3 Bucket Variables
# ============================================================================

variable "create_s3_bucket" {
  description = "Whether to create an S3 bucket for Loki logs storage"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "Custom S3 bucket name. If null, auto-generated as hs-{env}-loki-logs-storage"
  type        = string
  default     = null
}

variable "s3_force_destroy" {
  description = "Whether to allow S3 bucket deletion with objects in it"
  type        = bool
  default     = false
}

variable "s3_enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = false
}

variable "s3_sse_algorithm" {
  description = "Server-side encryption algorithm for S3 bucket (AES256 or aws:kms)"
  type        = string
  default     = "AES256"
}

variable "s3_kms_master_key_id" {
  description = "KMS key ID for S3 encryption (required if s3_sse_algorithm is aws:kms)"
  type        = string
  default     = null
}

variable "s3_server_access_logging" {
  description = "S3 server access logging configuration"
  type = object({
    enabled       = bool
    target_bucket = string
    target_prefix = optional(string, "")
  })
  default = {
    enabled       = false
    target_bucket = ""
    target_prefix = ""
  }
}

variable "s3_lifecycle_rules" {
  description = "List of lifecycle rules for the S3 bucket. See terraform-aws-modules/s3-bucket documentation for format."
  type        = any
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "hyperswitch"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
