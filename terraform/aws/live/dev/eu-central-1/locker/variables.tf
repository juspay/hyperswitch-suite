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
  description = "VPC ID where locker will be deployed"
  type        = string
}

variable "locker_subnet_id" {
  description = "Subnet ID for locker instance (private subnet recommended)"
  type        = string
}

variable "rds_cidr" {
  description = "CIDR block for RDS database access"
  type        = string
}

# ============================================================================
# Instance Configuration
# ============================================================================
variable "ami_id" {
  description = "AMI ID for locker instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for locker"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key pair name for EC2 instance"
  type        = string
}

# ============================================================================
# Security Configuration
# ============================================================================
variable "jump_host_security_group_id" {
  description = "Security group ID of jump host for SSH access"
  type        = string
}

# ============================================================================
# Logging Configuration
# ============================================================================
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

# ============================================================================
# Tags
# ============================================================================
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
