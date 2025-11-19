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

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
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
variable "ami_id" {
  description = "AMI ID for jump hosts (defaults to latest Amazon Linux 2 if not provided)"
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
# Tags
# ============================================================================
variable "common_tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Security Group Rules Configuration
# ============================================================================
variable "external_jump_egress_sg_ids" {
  description = "List of additional security group IDs for external jump host egress (beyond the hardcoded internal jump SSH access)"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    sg_id       = string
  }))
  default = []
}

variable "internal_jump_egress_sg_ids" {
  description = "List of security group IDs for internal jump host egress (e.g., RDS, ElastiCache, etc.)"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    sg_id       = string
  }))
  default = []
}
