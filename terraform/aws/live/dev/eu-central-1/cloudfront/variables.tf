# ============================================================================
# Variables - Environment Configuration
# ============================================================================

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
  description = "Project name"
  type        = string
  default     = "hyperswitch"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "hyperswitch"
    ManagedBy   = "terraform-IaC"
    Region      = "eu-central-1"
  }
}

# ============================================================================
# Logging Configuration
# ============================================================================
# Three logging scenarios:
# 1. Use existing bucket: enable_logging=true, provide log_bucket_arn
# 2. Create new bucket: enable_logging=true, create_log_bucket=true
# 3. Disable logging: enable_logging=false

variable "enable_logging" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = true
}

variable "create_log_bucket" {
  description = "Create new S3 bucket for logging (only if enable_logging=true and log_bucket_arn is not provided)"
  type        = bool
  default     = false
}

variable "log_bucket_arn" {
  description = "ARN of existing S3 bucket for CloudFront logs (e.g., arn:aws:s3:::my-cloudfront-logs). If provided, create_log_bucket is ignored."
  type        = string
  default     = null

  validation {
    condition     = var.log_bucket_arn == null || can(regex("^arn:aws:s3:::[a-z0-9][a-z0-9\\.-]*[a-z0-9]$", var.log_bucket_arn))
    error_message = "log_bucket_arn must be a valid S3 bucket ARN (e.g., arn:aws:s3:::bucket-name)."
  }
}

variable "log_prefix" {
  description = "Prefix for CloudFront log files in the S3 bucket"
  type        = string
  default     = "cloudfront/"
}