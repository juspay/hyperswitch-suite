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
# CloudFront Configuration
# ============================================================================
# Note: All CloudFront configuration (distributions, origins, cache behaviors,
# OACs, response headers policies, and CloudFront functions) is now loaded
# from config.yaml via locals.tf

# ============================================================================
# Logging Configuration
# ============================================================================

variable "enable_logging" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = true
}

variable "create_log_bucket" {
  description = "Create new S3 bucket for logging"
  type        = bool
  default     = false
}

variable "log_bucket" {
  description = "Existing S3 bucket configuration for CloudFront logs"
  type = object({
    bucket_name = string
    bucket_arn  = string
    bucket_domain_name = string
    prefix      = optional(string)
  })
  default = null
}

# Note: origin_access_controls, cloudfront_functions, and response_headers_policies
# are now loaded from config.yaml and do not need variable definitions