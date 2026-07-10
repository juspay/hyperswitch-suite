variable "region" {
  description = "(Optional) Region where this resource will be managed. Defaults to the Region set in the provider configuration"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (e.g., dev, integ, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where jump host will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the jump host (typically a private subnet)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for jump host (defaults to latest Amazon Linux 2023)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type for jump host"
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

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period"
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_migration_mode" {
  description = "Enable SSM SendCommand permissions for Packer migration. Should be disabled after migration is complete for security."
  type        = bool
  default     = false
}

variable "enable_ssm_session_encryption" {
  description = "Enable KMS encryption for SSM Session Manager sessions"
  type        = bool
  default     = true
}

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
  description = "Whether to create a CloudWatch log group for SSM session logs."
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
  description = "Name prefix for the SSM CloudWatch log group. Only used when create_ssm_cloudwatch_log_group=true."
  type        = string
  default     = "/aws/ssm/session-logs"
}

variable "ssm_s3_logging_enabled" {
  description = "Enable S3 logging for SSM sessions"
  type        = bool
  default     = false
}

variable "ssm_s3_bucket_name" {
  description = "S3 bucket name for SSM session logs. Required when ssm_s3_logging_enabled=true and create_ssm_s3_bucket=false."
  type        = string
  default     = ""
}

variable "create_ssm_s3_bucket" {
  description = "Whether to create an S3 bucket for SSM session logs."
  type        = bool
  default     = false
}

variable "ssm_s3_bucket_name_prefix" {
  description = "Name prefix for the SSM S3 bucket. Only used when create_ssm_s3_bucket=true."
  type        = string
  default     = "ssm-session-logs"
}

variable "ssm_s3_bucket_versioning" {
  description = "Enable versioning for the SSM S3 bucket."
  type        = bool
  default     = true
}

variable "ssm_s3_bucket_lifecycle_days" {
  description = "Number of days before transitioning objects to Glacier. Set to 0 to disable lifecycle rules."
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
  description = "Linux shell profile for SSM sessions. Runs when session starts."
  type        = string
  default     = ""
}

variable "ssm_shell_profile_windows" {
  description = "Windows shell profile for SSM sessions."
  type        = string
  default     = ""
}

variable "additional_userdata" {
  description = "Additional shell script to append to the default userdata. Runs after the built-in userdata.sh."
  type        = string
  default     = ""
}
