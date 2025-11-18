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

variable "ingress_rules" {
  description = "Ingress rules for ASG security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, or 'sg_id' for security groups"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr        = optional(list(string))  # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
    ipv6_cidr   = optional(list(string))  # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id       = optional(list(string))  # Security Group IDs
  }))
  default = []
}

variable "egress_rules" {
  description = "Egress rules for ASG security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, or 'sg_id' for security groups"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr        = optional(list(string))  # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
    ipv6_cidr   = optional(list(string))  # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id       = optional(list(string))  # Security Group IDs
  }))
  default = []
}

variable "lb_ingress_rules" {
  description = "Additional ingress rules for external load balancer security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, or 'sg_id' for security groups"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr        = optional(list(string))  # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
    ipv6_cidr   = optional(list(string))  # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id       = optional(list(string))  # Security Group IDs
  }))
  default = []
}

variable "lb_egress_rules" {
  description = "Additional egress rules for external load balancer security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, or 'sg_id' for security groups"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr        = optional(list(string))  # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
    ipv6_cidr   = optional(list(string))  # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id       = optional(list(string))  # Security Group IDs
  }))
  default = []
}

# NOTE: eks_security_group_id is NOT needed for Envoy proxy
# Traffic flow: CloudFront → External ALB → Envoy → Internal ALB → EKS
# (Different from Squid where EKS → Squid → Internet)

# =========================================================================
# Port Configuration Variables (Environment-specific)
# =========================================================================

variable "alb_http_listener_port" {
  description = "Port for ALB HTTP listener"
  type        = number
  default     = 80  # Dev uses standard HTTP port
}

variable "alb_https_listener_port" {
  description = "Port for ALB HTTPS listener"
  type        = number
  default     = 443
}

variable "envoy_traffic_port" {
  description = "Port where Envoy instances listen for traffic from ALB (target group port) - ALB forwards traffic to this port"
  type        = number
  default     = 80  # Dev uses port 80
}

variable "envoy_health_check_port" {
  description = "Port for Envoy health check endpoint - ALB sends GET /healthz requests to this port"
  type        = number
  default     = 80
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
  default     = "t3.small"
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
  default     = 2
}

variable "desired_capacity" {
  description = "Desired ASG capacity"
  type        = number
  default     = 1
}

variable "create_logs_bucket" {
  description = "Whether to create a new S3 bucket for logs"
  type        = bool
  default     = true
}

variable "logs_bucket_name" {
  description = "S3 bucket name for logs (required if create_logs_bucket=false)"
  type        = string
  default     = ""
}

variable "logs_bucket_arn" {
  description = "S3 bucket ARN for logs (required if create_logs_bucket=false)"
  type        = string
  default     = ""
}

variable "create_config_bucket" {
  description = "Whether to create a new S3 bucket for configuration files"
  type        = bool
  default     = false
}

variable "config_bucket_name" {
  description = "S3 bucket name for configurations (required if create_config_bucket=false)"
  type        = string
  default     = ""
}

variable "config_bucket_arn" {
  description = "S3 bucket ARN for configurations (required if create_config_bucket=false)"
  type        = string
  default     = ""
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

variable "envoy_config_filename" {
  description = "Name of the main Envoy config file (e.g., 'envoy.yaml', 'envoy-dev.yaml'). This file receives template variable substitution."
  type        = string
  default     = "envoy.yaml"
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

# =========================================================================
# SSL/TLS Configuration
# =========================================================================

variable "enable_https_listener" {
  description = "Enable HTTPS listener on port 443"
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS listener"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_http_to_https_redirect" {
  description = "Enable HTTP to HTTPS redirect"
  type        = bool
  default     = false
}

# =========================================================================
# Advanced Listener Rules
# =========================================================================

variable "listener_rules" {
  description = "Advanced listener rules for header-based routing"
  type = list(object({
    priority = number
    actions = list(object({
      type             = string
      target_group_arn = optional(string)
      redirect = optional(object({
        port        = string
        protocol    = string
        status_code = string
      }))
      fixed_response = optional(object({
        content_type = string
        message_body = optional(string)
        status_code  = string
      }))
    }))
    conditions = list(object({
      host_header = optional(object({
        values = list(string)
      }))
      http_header = optional(object({
        http_header_name = string
        values           = list(string)
      }))
      path_pattern = optional(object({
        values = list(string)
      }))
      source_ip = optional(object({
        values = list(string)
      }))
    }))
  }))
  default = []
}

# =========================================================================
# WAF Configuration
# =========================================================================

variable "enable_waf" {
  description = "Enable AWS WAF WebACL"
  type        = bool
  default     = false
}

variable "waf_web_acl_arn" {
  description = "ARN of AWS WAFv2 WebACL"
  type        = string
  default     = null
}

# =========================================================================
# Target Group Configuration
# =========================================================================

variable "target_group_protocol" {
  description = "Protocol for target group (HTTP or HTTPS)"
  type        = string
  default     = "HTTP"
}

# =========================================================================
# VPC Endpoint Configuration
# =========================================================================

variable "s3_vpc_endpoint_prefix_list_id" {
  description = "Prefix list ID for S3 VPC endpoint"
  type        = string
  default     = null
}

# =========================================================================
# Spot Instances Configuration
# =========================================================================

variable "enable_spot_instances" {
  description = "Enable mixed instances policy with spot instances"
  type        = bool
  default     = false
}

variable "spot_instance_percentage" {
  description = "Percentage of spot instances (0-100)"
  type        = number
  default     = 50
}

variable "on_demand_base_capacity" {
  description = "Minimum number of on-demand instances"
  type        = number
  default     = 1
}

variable "spot_allocation_strategy" {
  description = "Strategy for allocating spot instances"
  type        = string
  default     = "capacity-optimized"
}

variable "enable_capacity_rebalance" {
  description = "Enable capacity rebalancing for spot instances"
  type        = bool
  default     = false
}

# =========================================================================
# ASG Advanced Configuration
# =========================================================================

variable "termination_policies" {
  description = "List of policies for instance termination"
  type        = list(string)
  default     = ["OldestLaunchTemplate", "OldestInstance", "Default"]
}

variable "max_instance_lifetime" {
  description = "Maximum lifetime of instances in seconds (0 = no limit)"
  type        = number
  default     = 0
}

# =========================================================================
# Auto Scaling Policies Configuration
# =========================================================================

variable "enable_autoscaling" {
  description = "Enable auto-scaling policies for the ASG"
  type        = bool
  default     = false
}

variable "scaling_policies" {
  description = "Configuration for auto-scaling policies"
  type = object({
    cpu_target_tracking = optional(object({
      enabled      = optional(bool, false)
      target_value = optional(number, 70.0)
    }), {})
    memory_target_tracking = optional(object({
      enabled      = optional(bool, false)
      target_value = optional(number, 70.0)
    }), {})
  })
  default = {
    cpu_target_tracking = {
      enabled      = false
      target_value = 70.0
    }
    memory_target_tracking = {
      enabled      = false
      target_value = 70.0
    }
  }
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
