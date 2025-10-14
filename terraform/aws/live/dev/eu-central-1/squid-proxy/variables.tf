variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "hyperswitch"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "proxy_subnet_ids" {
  description = "Subnet IDs for proxy instances"
  type        = list(string)
}

variable "lb_subnet_ids" {
  description = "Subnet IDs for load balancer"
  type        = list(string)
}

variable "eks_security_group_id" {
  description = "EKS cluster security group ID"
  type        = string
}

variable "squid_port" {
  description = "Squid proxy port"
  type        = number
  default     = 3128
}

variable "ami_id" {
  description = "AMI ID for Squid instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum ASG size"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum ASG size"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired ASG capacity"
  type        = number
  default     = 1
}

variable "config_bucket_name" {
  description = "S3 bucket name for configurations"
  type        = string
}

variable "config_bucket_arn" {
  description = "S3 bucket ARN for configurations"
  type        = string
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "create_nlb" {
  description = "Create new NLB or use existing"
  type        = bool
  default     = true
}

variable "existing_lb_name" {
  description = "Name of existing load balancer"
  type        = string
  default     = null
}

variable "existing_lb_arn" {
  description = "ARN of existing load balancer"
  type        = string
  default     = null
}

variable "listener_rule_priority" {
  description = "Priority for listener rule on existing LB"
  type        = number
  default     = 100
}

