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
  description = "Subnet ID for locker instance. Required if create_subnet is false"
  type        = string
  default     = null
}

variable "create_subnet" {
  description = "Whether to create a new subnet for the locker instance"
  type        = bool
  default     = false
}

variable "subnet_cidr_block" {
  description = "CIDR block for the new subnet. Required if create_subnet is true"
  type        = string
  default     = null
}

variable "subnet_availability_zone" {
  description = "Availability zone for the new subnet. If not provided, will use the first available AZ in the region"
  type        = string
  default     = null
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
  description = "SSH key pair name. Required if create_key_pair is false"
  type        = string
  default     = null
}

variable "create_key_pair" {
  description = "Whether to create a new SSH key pair. If true, public_key can be provided or will be auto-generated"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key material for creating new SSH key pair. Optional - if not provided when create_key_pair is true, a new key pair will be auto-generated and stored in SSM Parameter Store"
  type        = string
  default     = null
}

# ============================================================================
# Security Configuration
# ============================================================================
variable "locker_security_group_id" {
  description = "Existing security group ID for the locker instance. If not provided, a new security group will be created"
  type        = string
  default     = null
}

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
