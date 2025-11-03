variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string

  validation {
    condition     = contains(["dev", "integ", "prod", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, integ, prod, sandbox"
  }
}

variable "project_name" {
  description = "Project name for tagging and naming resources"
  type        = string
  default     = "hyperswitch"
}

# ============================================================================
# S3 Bucket Configuration
# ============================================================================

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state (must be globally unique)"
  type        = string
}

variable "allow_destroy" {
  description = "Allow destruction of the bucket (should be false for prod)"
  type        = bool
  default     = false
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm for S3 (AES256 or aws:kms)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "SSE algorithm must be either AES256 or aws:kms"
  }
}

variable "kms_master_key_id" {
  description = "KMS key ID for S3 encryption (required if sse_algorithm is aws:kms)"
  type        = string
  default     = null
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
}

variable "dynamodb_billing_mode" {
  description = "Billing mode for DynamoDB (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"  # Cost-effective for state locking workloads

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.dynamodb_billing_mode)
    error_message = "Billing mode must be either PROVISIONED or PAY_PER_REQUEST"
  }
}

variable "dynamodb_read_capacity" {
  description = "Read capacity units for DynamoDB (only used with PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "Write capacity units for DynamoDB (only used with PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "enable_dynamodb_pitr" {
  description = "Enable point-in-time recovery for DynamoDB table"
  type        = bool
  default     = false  # Can be enabled for prod environments
}

variable "dynamodb_kms_key_arn" {
  description = "ARN of KMS key for DynamoDB encryption (null uses AWS managed key)"
  type        = string
  default     = null
}

# ============================================================================
# Tagging
# ============================================================================

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
