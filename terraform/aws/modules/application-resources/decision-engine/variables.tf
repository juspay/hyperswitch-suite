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
  default     = "decision-engine"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =========================================================================
# EKS OIDC Configuration
# =========================================================================

variable "cluster_service_accounts" {
  description = "Map of EKS cluster names to their respective list of Kubernetes service accounts (namespace and service account name)"
  type = map(list(object({
    namespace = string
    name      = string
  })))
  default = {}
}

variable "additional_assume_role_statements" {
  description = "Additional IAM assume role policy statements to append"
  type        = list(any)
  default     = []
}

# =========================================================================
# IAM Role Configuration
# =========================================================================

variable "role_name" {
  description = "Custom IAM role name. If null, auto-generated as {environment}-{project}-{app}-role"
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

# =========================================================================
# Assume Role Principals
# =========================================================================

variable "assume_role_principals" {
  description = "List of AWS principal ARNs allowed to assume this role (e.g., ['arn:aws:iam::123456789012:root'])"
  type        = list(string)
  default     = []
}

# =========================================================================
# Policy Attachments
# =========================================================================

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

# =========================================================================
# Inline Policies
# =========================================================================

variable "inline_policies" {
  description = "Map of inline policy names to JSON policy documents to attach to the role"
  type        = map(string)
  default     = {}
}

# =========================================================================
# S3 Bucket Configuration
# =========================================================================

variable "s3_bucket" {
  description = "Configuration for the Decision Engine S3 bucket"
  type = object({
    enabled                       = optional(bool, true)
    bucket_name                   = optional(string, null)
    force_destroy                 = optional(bool, false)
    versioning_enabled            = optional(bool, true)
    lifecycle_rules               = optional(list(object({
      id                            = string
      enabled                       = bool
      prefix                        = optional(string, "")
      expiration_days               = optional(number, null)
      noncurrent_version_expiration = optional(number, null)
      transition                    = optional(list(object({
        days          = number
        storage_class = string
      })), [])
    })), [])
  })
  default = {}
}
