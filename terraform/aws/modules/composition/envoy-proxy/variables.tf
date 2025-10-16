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
  description = "Subnet IDs for proxy instances (private subnets)"
  type        = list(string)
}

variable "lb_subnet_ids" {
  description = "Subnet IDs for load balancer"
  type        = list(string)
}

variable "eks_security_group_id" {
  description = "Security group ID of the EKS cluster"
  type        = string
}

variable "envoy_admin_port" {
  description = "Port for Envoy admin interface"
  type        = number
  default     = 9901
}

variable "envoy_listener_port" {
  description = "Port for Envoy listener"
  type        = number
  default     = 10000
}

variable "ami_id" {
  description = "AMI ID for Envoy instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Envoy proxy"
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
  description = "Name of S3 bucket containing Envoy configuration files"
  type        = string
}

variable "config_bucket_arn" {
  description = "ARN of S3 bucket containing Envoy configuration files"
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
