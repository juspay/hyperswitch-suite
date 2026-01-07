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
  description = "Public subnet ID for external jump host"
  type        = string
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
