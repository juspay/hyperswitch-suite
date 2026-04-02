variable "environment" {
  description = "Environment name (dev/integ/prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "AWS region for resource creation"
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
# Feature: KMS Key
# =========================================================================
# Set to {} to disable KMS key creation and policy
# Set create = true to create a new KMS key (single or multi-region, or replica)
# Set create = false and provide key_arn to use existing KMS key (policy will be created)

variable "kms" {
  description = "KMS key configuration. Set to {} to disable KMS key and policy. Set create=true to create key, or create=false with key_arn to use existing key. Policy and tags are handled internally by the module."
  type = object({
    # Key source: either create new or use existing
    create  = optional(bool, false)  # Set true to create KMS key, false to use existing
    key_arn = optional(string, null) # Existing KMS key ARN (used when create=false)

    # Key creation settings (used when create=true)
    description  = optional(string, null)
    multi_region = optional(bool, false)

    # Replica key settings
    create_replica           = optional(bool, false)
    create_replica_external  = optional(bool, false)
    primary_key_arn          = optional(string, null)
    primary_external_key_arn = optional(string, null)

    # External key settings
    create_external     = optional(bool, false)
    key_material_base64 = optional(string, null)
    valid_to            = optional(string, null)

    # Key specifications
    key_usage                = optional(string, null)
    customer_master_key_spec = optional(string, null)
    key_spec                 = optional(string, null)
    deletion_window_in_days  = optional(number, null)

    # Key settings
    is_enabled                         = optional(bool, null)
    enable_key_rotation                = optional(bool, true)
    rotation_period_in_days            = optional(number, null)
    bypass_policy_lockout_safety_check = optional(bool, null)

    # Aliases
    aliases                 = optional(list(string), [])
    aliases_use_name_prefix = optional(bool, false)

    # Access control (for key policy)
    key_administrators = optional(list(string), [])
    key_users          = optional(list(string), [])
    key_service_users  = optional(list(string), [])
    key_owners         = optional(list(string), [])
  })
  default = {}
}

# =========================================================================
# Feature: S3 Bucket for Dashboard Themes
# =========================================================================
# Set to {} to disable dashboard themes S3 bucket and policy
# Set create = true to create new bucket, or create = false with bucket_arn to use existing

variable "s3_dashboard_themes" {
  description = "S3 bucket configuration for dashboard themes. Set to {} to disable. Set create=true to create bucket, or create=false with bucket_arn to use existing."
  type = object({
    create     = optional(bool, false)  # Set true to create S3 bucket, false to use existing
    bucket_arn = optional(string, null) # Existing S3 bucket ARN (used when create=false)

    # Bucket creation settings (used when create=true)
    bucket_name        = optional(string, null) # Auto-generated if not provided
    force_destroy      = optional(bool, false)
    versioning_enabled = optional(bool, true)
  })
  default = {}
}

# =========================================================================
# Feature: S3 Bucket for File Uploads
# =========================================================================
# Set to {} to disable file uploads S3 bucket and policy
# Set create = true to create new bucket, or create = false with bucket_arn to use existing

variable "s3_file_uploads" {
  description = "S3 bucket configuration for file uploads. Set to {} to disable. Set create=true to create bucket, or create=false with bucket_arn to use existing."
  type = object({
    create     = optional(bool, false)  # Set true to create S3 bucket, false to use existing
    bucket_arn = optional(string, null) # Existing S3 bucket ARN (used when create=false)

    # Bucket creation settings (used when create=true)
    bucket_name        = optional(string, null) # Auto-generated if not provided
    force_destroy      = optional(bool, false)
    versioning_enabled = optional(bool, true)
  })
  default = {}
}

# =========================================================================
# Feature: SES (Simple Email Service)
# =========================================================================
# Only accepts existing SES configuration ARN - does NOT create SES resources

variable "ses" {
  description = "SES configuration. Set to {} to disable SES policy. Only accepts existing SES role ARN (does NOT create SES resources)."
  type = object({
    enabled  = optional(bool, false)  # Set true to enable SES policy
    role_arn = optional(string, null) # Existing SES role ARN to assume
  })
  default = {}
}

# =========================================================================
# Feature: Secrets Manager
# =========================================================================

variable "secrets_manager" {
  description = "Secrets Manager configuration. Set to {} to disable Secrets Manager policy."
  type = object({
    enabled     = optional(bool, false)
    secret_arns = optional(list(string), [])
  })
  default = {}
}

# =========================================================================
# Feature: Lambda Functions
# =========================================================================
# Set to {} to disable Lambda policy
# Set enabled=true and provide function_arns for specific function permissions

variable "lambda" {
  description = "Lambda function configuration. Set to {} to disable Lambda policy. Set enabled=true to allow Lambda operations on specific functions."
  type = object({
    enabled       = optional(bool, false)
    function_arns = optional(list(string), []) # List of Lambda function ARNs to allow invoke/all operations on
    # If empty list, only list/get/create permissions will be granted (no specific function access)
  })
  default = {}
}

# =========================================================================
# Feature: Cross-Account Assume Role
# =========================================================================

variable "assume_role" {
  description = "Cross-account assume role configuration. Set to {} to disable assume role policy."
  type = object({
    enabled          = optional(bool, false)
    target_role_arns = optional(list(string), []) # List of role ARNs to allow assuming
    account_id       = optional(string, null)     # Account ID for wildcard role assumption
  })
  default = {}
}
