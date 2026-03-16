variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "loki"
}

variable "role_name" {
  description = "Custom IAM role name. If null, auto-generated as {project}-{env}-{app}-role"
  type        = string
  default     = null
}

variable "role_description" {
  description = "Custom IAM role description"
  type        = string
  default     = null
}

variable "role_path" {
  description = "IAM role path"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration for the role (in seconds)"
  type        = number
  default     = 3600
}

variable "force_detach_policies" {
  description = "Whether to force detaching policies when destroying the role"
  type        = bool
  default     = true
}

variable "oidc_providers" {
  description = "OIDC provider trust for EKS service accounts"
  type = map(object({
    provider_arn = string
    conditions = list(object({
      type   = string
      claim  = string
      values = list(string)
    }))
  }))
  default = null
}

variable "assume_role_principals" {
  description = "Cross-account assume role trust"
  type = list(object({
    type        = string
    identifiers = list(string)
  }))
  default = null
}

variable "aws_managed_policy_names" {
  description = "List of AWS managed policy names to attach"
  type        = list(string)
  default     = []
}

variable "customer_managed_policy_arns" {
  description = "List of customer managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policies for role-specific permissions"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# S3 Bucket Configuration
# ==============================================================================

variable "create_s3_bucket" {
  description = "Whether to create an S3 bucket alongside the IAM role"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Custom S3 bucket name. If null, auto-generated"
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

  validation {
    condition     = contains(["AES256", "aws:kms"], var.s3_sse_algorithm)
    error_message = "SSE algorithm must be either AES256 or aws:kms"
  }
}

variable "s3_kms_master_key_id" {
  description = "KMS key ID for S3 encryption (required if s3_sse_algorithm is aws:kms)"
  type        = string
  default     = null
}

variable "s3_lifecycle_rules" {
  description = "List of lifecycle rules for the S3 bucket"
  type        = any
  default     = []
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

variable "s3_permissions_policy" {
  description = "JSON-encoded IAM policy granting S3 permissions for the created bucket"
  type        = string
  default     = null
}
