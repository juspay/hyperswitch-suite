variable "environment" {
  description = "Environment name (dev/integ/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "integ", "prod"], var.environment)
    error_message = "Environment must be one of: dev, integ, prod"
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "ami_id" {
  description = "Custom AMI ID for locker instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key pair name for EC2 instance"
  type        = string
}

variable "jump_host_security_group_id" {
  description = "Security group ID of jump host for SSH access"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "rds_cidr" {
  description = "CIDR block for RDS database access"
  type        = string
  validation {
    condition     = can(regex("^(\\d{1,3}\\.){3}\\d{1,3}/\\d{1,2}$", var.rds_cidr))
    error_message = "rds_cidr must be a valid CIDR block (e.g., 10.0.0.0/32)"
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "locker_subnet_id" {
  description = "Subnet ID for the locker instance"
  type        = string
}
