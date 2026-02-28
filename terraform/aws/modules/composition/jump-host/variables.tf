variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
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
  description = "VPC ID where jump hosts will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for external jump host"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for internal jump host"
  type        = string
}

variable "external_jump_ami_id" {
  description = "AMI ID for external jump host (defaults to latest Amazon Linux 2)"
  type        = string
  default     = null
}

variable "internal_jump_ami_id" {
  description = "AMI ID for internal jump host (defaults to latest Amazon Linux 2)"
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
  description = "Enable SSM SendCommand permissions for Packer migration. Should be disabled after migration is complete for security. Only affects: ssm:DescribeInstanceInformation, ssm:SendCommand, ssm:GetCommandInvocation, ssm:ListCommandInvocations"
  type        = bool
  default     = false
}

variable "enable_internal_jump_ssm" {
  description = "Enable SSM Session Manager access for internal jump host. When true, adds SSM policies to internal jump IAM role"
  type        = bool
  default     = false
}