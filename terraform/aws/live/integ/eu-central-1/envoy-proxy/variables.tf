variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "integ"
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

# NOTE: eks_security_group_id is NOT needed for Envoy proxy
# Traffic flow: CloudFront → External ALB → Envoy → Internal ALB → EKS
# (Different from Squid where EKS → Squid → Internet)

variable "envoy_admin_port" {
  description = "Envoy admin port"
  type        = number
  default     = 9901
}

variable "envoy_listener_port" {
  description = "Envoy listener port"
  type        = number
  default     = 10000
}

# =========================================================================
# Port Configuration Variables (Environment-specific)
# =========================================================================

variable "alb_http_listener_port" {
  description = "Port for ALB HTTP listener"
  type        = number
  default     = 80  # Integ uses standard HTTP port
}

variable "alb_https_listener_port" {
  description = "Port for ALB HTTPS listener"
  type        = number
  default     = 443
}

variable "envoy_traffic_port" {
  description = "Port where Envoy listens for traffic from ALB"
  type        = number
  default     = 80  # Integ uses port 80
}

variable "envoy_health_check_port" {
  description = "Port for Envoy health check endpoint"
  type        = number
  default     = 8081
}

variable "envoy_upstream_port" {
  description = "Port for Envoy to forward traffic to upstream"
  type        = number
  default     = 80
}

variable "ami_id" {
  description = "AMI ID for Envoy instances (ignored if use_existing_launch_template = true)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type (ignored if use_existing_launch_template = true)"
  type        = string
  default     = "t3.medium"
}

variable "use_existing_launch_template" {
  description = "Whether to use an existing launch template instead of creating a new one"
  type        = bool
  default     = false
}

variable "existing_launch_template_id" {
  description = "ID of existing launch template to use (required if use_existing_launch_template = true)"
  type        = string
  default     = null
}

variable "existing_launch_template_version" {
  description = "Version of existing launch template to use ($Latest, $Default, or specific version number)"
  type        = string
  default     = "$Latest"
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
  default     = 3
}

variable "desired_capacity" {
  description = "Desired ASG capacity"
  type        = number
  default     = 2
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
  default     = true
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "generate_ssh_key" {
  description = "Whether to auto-generate SSH key pair"
  type        = bool
  default     = true
}

variable "upload_config_to_s3" {
  description = "Whether to upload config files from local config/ directory to S3"
  type        = bool
  default     = false
}

variable "hyperswitch_cloudfront_dns" {
  description = "CloudFront DNS for Hyperswitch (for envoy.yaml templating)"
  type        = string
  default     = ""
}

variable "internal_loadbalancer_dns" {
  description = "Internal ALB DNS (for envoy.yaml templating)"
  type        = string
  default     = ""
}

variable "create_lb" {
  description = "Create new LB or use existing"
  type        = bool
  default     = true
}

variable "create_target_group" {
  description = "Create new target group or use existing"
  type        = bool
  default     = true
}

variable "existing_tg_arn" {
  description = "ARN of existing target group"
  type        = string
  default     = null
}

variable "existing_lb_arn" {
  description = "ARN of existing load balancer (required when create_lb = false)"
  type        = string
  default     = null
}

variable "existing_lb_security_group_id" {
  description = "Security group ID of existing ALB (required when create_lb = false)"
  type        = string
  default     = null
}

variable "enable_instance_refresh" {
  description = "Enable automatic instance refresh when config changes"
  type        = bool
  default     = true
}

variable "create_iam_role" {
  description = "Whether to create a new IAM role or use existing one"
  type        = bool
  default     = true
}

variable "existing_iam_role_name" {
  description = "Name of existing IAM role to use (only if create_iam_role = false)"
  type        = string
  default     = null
}

variable "create_instance_profile" {
  description = "Whether to create a new instance profile for existing IAM role (only relevant when create_iam_role = false)"
  type        = bool
  default     = true
}

variable "existing_iam_instance_profile_name" {
  description = "Name of existing IAM instance profile to use (only if create_iam_role = false AND create_instance_profile = false)"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
