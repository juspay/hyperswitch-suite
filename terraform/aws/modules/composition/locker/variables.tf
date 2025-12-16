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
  description = "SSH key pair name. Required if create_key_pair is false. If create_key_pair is true and this is provided, it will be used as the name for the new key pair; otherwise an auto-generated name will be used"
  type        = string
  default     = null
  validation {
    condition     = var.create_key_pair || var.key_name != null
    error_message = "key_name must be provided when create_key_pair is false"
  }
}

variable "create_key_pair" {
  description = "Whether to create a new SSH key pair. If true, public_key must be provided"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key material for creating new SSH key pair. Optional - if not provided when create_key_pair is true, a new key pair will be auto-generated and the private key will be stored in SSM Parameter Store"
  type        = string
  default     = null
}

variable "locker_security_group_id" {
  description = "Existing security group ID for the locker instance. If not provided, a new security group will be created"
  type        = string
  default     = null
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

variable "rds_security_group_id" {
  description = "Security group ID of RDS database for database access"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "locker_subnet_id" {
  description = "Subnet ID for the locker instance. Required if create_subnet is false"
  type        = string
  default     = null
  validation {
    condition     = var.create_subnet || var.locker_subnet_id != null
    error_message = "locker_subnet_id must be provided when create_subnet is false"
  }
}

variable "create_subnet" {
  description = "Whether to create a new subnet for the locker instance. If true, subnet_cidr_block must be provided"
  type        = bool
  default     = false
}

variable "subnet_cidr_block" {
  description = "CIDR block for the new subnet. Required if create_subnet is true"
  type        = string
  default     = null
  validation {
    condition     = var.create_subnet ? var.subnet_cidr_block != null : true
    error_message = "subnet_cidr_block must be provided when create_subnet is true"
  }
}

variable "subnet_availability_zone" {
  description = "Availability zone for the new subnet. If not provided, will use the first available AZ in the region"
  type        = string
  default     = null
}
