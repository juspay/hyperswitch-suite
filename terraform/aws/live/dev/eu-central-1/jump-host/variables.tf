# ============================================================================
# Environment & Project Configuration
# ============================================================================
variable "environment" {
  description = "Environment name (e.g., dev, integ, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hyperswitch"
}

# ============================================================================
# Network Configuration
# ============================================================================
variable "vpc_id" {
  description = "VPC ID where jump hosts will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for external jump host. Required when enable_external_jump is true."
  type        = string
  default     = null
}

variable "private_subnet_id" {
  description = "Private subnet ID for internal jump host"
  type        = string
}

# ============================================================================
# Instance Configuration
# ============================================================================
variable "external_jump_ami_id" {
  description = "AMI ID for external jump host (defaults to latest Amazon Linux 2 if not provided)"
  type        = string
  default     = null
}

variable "internal_jump_ami_id" {
  description = "AMI ID for internal jump host (defaults to latest Amazon Linux 2 if not provided)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type for jump hosts"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of the root volume in GiB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

# ============================================================================
# Logging Configuration
# ============================================================================
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# ============================================================================
# Migration Mode Configuration
# ============================================================================
variable "enable_migration_mode" {
  description = "Enable SSM SendCommand permissions for Packer migration. Should be disabled after migration is complete for security. Only affects: ssm:DescribeInstanceInformation, ssm:SendCommand, ssm:GetCommandInvocation, ssm:ListCommandInvocations"
  type        = bool
  default     = false
}

variable "ssm_parameter_overwrite" {
  description = "Allow overwriting existing SSM parameters. Set to true if parameters were created outside Terraform or state was lost. Default is false for safety."
  type        = bool
  default     = false
}

# ============================================================================
# Tags
# ============================================================================
variable "common_tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# SSM Session Manager Configuration
# ============================================================================
variable "enable_internal_jump_ssm" {
  description = "Enable SSM Session Manager access for internal jump host. When true, SSM policies will be dynamically attached to the internal jump IAM role"
  type        = bool
  default     = false
}

# ============================================================================
# Jump Host Mode Configuration
# ============================================================================
variable "enable_external_jump" {
  description = "Enable external jump host in public subnet. When false, only internal jump host is created in private subnet with SSM access forced on (cost-saving mode for lower environments)"
  type        = bool
  default     = true
}

variable "enable_ssm_session_encryption" {
  description = "Enable KMS encryption for SSM Session Manager sessions"
  type        = bool
  default     = true
}

# =========================================================================
# SSM Session Manager Preferences
# =========================================================================
variable "ssm_idle_session_timeout" {
  description = "Idle session timeout in minutes. Session terminates after this period of inactivity."
  type        = number
  default     = 10
}

variable "ssm_max_session_duration" {
  description = "Maximum session duration in minutes. Leave empty string for unlimited."
  type        = string
  default     = ""
}

variable "ssm_run_as_user" {
  description = "Default OS user to run sessions as (e.g., 'ubuntu'). When set, SSM creates OS users based on IAM user name and runs sessions as that user. Leave empty to disable run-as functionality (uses ssm-user)."
  type        = string
  default     = ""
}

variable "ssm_cloudwatch_logging_enabled" {
  description = "Enable CloudWatch logging for SSM sessions"
  type        = bool
  default     = true
}

variable "ssm_cloudwatch_log_group_name" {
  description = "CloudWatch log group name for SSM session logs. Required when ssm_cloudwatch_logging_enabled=true and create_ssm_cloudwatch_log_group=false. Ignored when create_ssm_cloudwatch_log_group=true."
  type        = string
  default     = ""
}

variable "create_ssm_cloudwatch_log_group" {
  description = "Whether to create a CloudWatch log group for SSM session logs. When true, a log group will be created and its name will be used. When false, ssm_cloudwatch_log_group_name must be provided if ssm_cloudwatch_logging_enabled is true."
  type        = bool
  default     = false
}

variable "ssm_cloudwatch_log_group_retention_days" {
  description = "CloudWatch log retention in days for SSM session logs. Only used when create_ssm_cloudwatch_log_group=true."
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.ssm_cloudwatch_log_group_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period"
  }
}

variable "ssm_cloudwatch_log_group_name_prefix" {
  description = "Name prefix for the SSM CloudWatch log group. Only used when create_ssm_cloudwatch_log_group=true. Final name will be '{prefix}-{environment}'. Defaults to '/aws/ssm/session-logs'."
  type        = string
  default     = "/aws/ssm/session-logs"
}

variable "ssm_s3_logging_enabled" {
  description = "Enable S3 logging for SSM sessions"
  type        = bool
  default     = false
}

variable "ssm_s3_bucket_name" {
  description = "S3 bucket name for SSM session logs. Required when ssm_s3_logging_enabled=true and create_ssm_s3_bucket=false. Ignored when create_ssm_s3_bucket=true."
  type        = string
  default     = ""
}

variable "create_ssm_s3_bucket" {
  description = "Whether to create an S3 bucket for SSM session logs. When true, a bucket will be created and its name will be used. When false, ssm_s3_bucket_name must be provided if ssm_s3_logging_enabled is true."
  type        = bool
  default     = false
}

variable "ssm_s3_bucket_name_prefix" {
  description = "Name prefix for the SSM S3 bucket. Only used when create_ssm_s3_bucket=true. Final name will be '{prefix}-{environment}-{region}-{account_id}'. Defaults to 'ssm-session-logs'."
  type        = string
  default     = "ssm-session-logs"
}

variable "ssm_s3_bucket_versioning" {
  description = "Enable versioning for the SSM S3 bucket. Only used when create_ssm_s3_bucket=true."
  type        = bool
  default     = true
}

variable "ssm_s3_bucket_lifecycle_days" {
  description = "Number of days before transitioning objects to Glacier. Set to 0 to disable lifecycle rules. Only used when create_ssm_s3_bucket=true."
  type        = number
  default     = 90
}

variable "ssm_s3_key_prefix" {
  description = "S3 key prefix for SSM session logs"
  type        = string
  default     = "session-manager"
}

variable "create_ssm_session_preferences" {
  description = "Whether to create the SSM Session Manager preferences document. Set to false if another environment in the same AWS account already manages this account-level setting."
  type        = bool
  default     = true
}

variable "ssm_shell_profile_linux" {
  description = "Linux shell profile for SSM sessions. Runs when session starts. Leave empty for no profile."
  type        = string
  default     = ""
}

variable "ssm_shell_profile_windows" {
  description = "Windows shell profile for SSM sessions. Leave empty for no Windows profile."
  type        = string
  default     = ""
}
