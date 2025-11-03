# ============================================================================
# General Configuration
# ============================================================================

variable "region" {
  description = "AWS region for the state bucket and DynamoDB table"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for tagging resources"
  type        = string
  default     = "hyperswitch"
}

# ============================================================================
# S3 Bucket Configuration
# ============================================================================

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state (must be globally unique)"
  type        = string
  default     = "hyperswitch-dev-terraform-state"

  # Note: S3 bucket names must be globally unique
  # If this name is taken, add a suffix like: hyperswitch-dev-terraform-state-YOURNAME
}

variable "allow_destroy" {
  description = "Allow destruction of the bucket (should be false for prod)"
  type        = bool
  default     = true  # Dev can be destroyed easily
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm for S3 (AES256 or aws:kms)"
  type        = string
  default     = "AES256"
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the state bucket"
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
  default = []  # No lifecycle rules by default - keep all state history
}

# ============================================================================
# DynamoDB Table Configuration
# ============================================================================

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "hyperswitch-dev-terraform-state-lock"

  # Note: Should match the naming convention of your state bucket
}

variable "dynamodb_billing_mode" {
  description = "Billing mode for DynamoDB (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"  # Cost-effective for state locking
}

variable "enable_dynamodb_pitr" {
  description = "Enable point-in-time recovery for DynamoDB table"
  type        = bool
  default     = false  # Can be enabled for additional safety in prod
}

# ============================================================================
# Tagging
# ============================================================================

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
