variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string

  validation {
    condition     = contains(["dev", "integ", "prod", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, integ, prod, sandbox"
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

variable "proxy_subnet_ids" {
  description = "Subnet IDs for proxy instances (private subnets with NAT)"
  type        = list(string)
}

variable "lb_subnet_ids" {
  description = "Subnet IDs for load balancer (service layer subnets)"
  type        = list(string)
}

variable "eks_security_group_id" {
  description = "Security group ID of the EKS cluster"
  type        = string
}

variable "squid_port" {
  description = "Port for Squid proxy"
  type        = number
  default     = 3128
}

variable "ami_id" {
  description = "AMI ID for Squid instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Squid proxy"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1
}

variable "config_bucket_name" {
  description = "Name of S3 bucket containing Squid configuration files"
  type        = string
}

variable "config_bucket_arn" {
  description = "ARN of S3 bucket containing Squid configuration files"
  type        = string
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Type of root EBS volume"
  type        = string
  default     = "gp3"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =========================================================================
# Existing Infrastructure Integration Variables
# =========================================================================

variable "create_nlb" {
  description = "Whether to create a new Network Load Balancer"
  type        = bool
  default     = true
}

variable "create_target_group" {
  description = "Whether to create a new target group"
  type        = bool
  default     = true
}

variable "existing_lb_arn" {
  description = "ARN of existing load balancer (required if create_nlb=false)"
  type        = string
  default     = null

  validation {
    condition     = var.create_nlb == true || var.existing_lb_arn != null
    error_message = "existing_lb_arn must be provided when create_nlb is false"
  }
}

variable "existing_lb_listener_arn" {
  description = "ARN of existing load balancer listener (required if create_nlb=false and attaching via listener rule)"
  type        = string
  default     = null
}

variable "existing_tg_arn" {
  description = "ARN of existing target group (required if create_target_group=false)"
  type        = string
  default     = null

  validation {
    condition     = var.create_target_group == true || var.existing_tg_arn != null
    error_message = "existing_tg_arn must be provided when create_target_group is false"
  }
}

# NOTE: Network Load Balancers don't support listener rules like ALBs do.
# When using an existing NLB, you have two options:
# 1. Manually update the existing listener's default action to forward to the target group created by this module
# 2. Use the existing target group by setting create_target_group=false and providing existing_tg_arn
