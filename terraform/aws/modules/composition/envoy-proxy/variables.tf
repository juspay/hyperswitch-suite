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
  description = "Subnet IDs for load balancer (public subnets for external ALB)"
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
  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, or sg_id
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), or 'sg_id' (Security Group)."
  }
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
  validation {
    condition = alltrue([
      for rule in var.egress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, or sg_id
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), or 'sg_id' (Security Group)."
  }
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

# =========================================================================
# Port Configuration Variables
# These allow per-environment port configuration (e.g., dev uses 80, prod uses 8080)
# =========================================================================

variable "alb_http_listener_port" {
  description = "Port for ALB HTTP listener (port that ALB listens on for incoming HTTP traffic)"
  type        = number
  default     = 80

  validation {
    condition     = var.alb_http_listener_port >= 1 && var.alb_http_listener_port <= 65535
    error_message = "ALB HTTP listener port must be between 1 and 65535"
  }
}

variable "alb_https_listener_port" {
  description = "Port for ALB HTTPS listener (port that ALB listens on for incoming HTTPS traffic)"
  type        = number
  default     = 443

  validation {
    condition     = var.alb_https_listener_port >= 1 && var.alb_https_listener_port <= 65535
    error_message = "ALB HTTPS listener port must be between 1 and 65535"
  }
}

variable "envoy_traffic_port" {
  description = "Port where Envoy instances listen for traffic from ALB (target group port) - ALB forwards traffic to this port"
  type        = number
  default     = 80

  validation {
    condition     = var.envoy_traffic_port >= 1 && var.envoy_traffic_port <= 65535
    error_message = "Envoy traffic port must be between 1 and 65535"
  }
}

variable "envoy_health_check_port" {
  description = "Port for Envoy health check endpoint - ALB sends GET /healthz requests to this port"
  type        = number
  default     = 80

  validation {
    condition     = var.envoy_health_check_port >= 1 && var.envoy_health_check_port <= 65535
    error_message = "Envoy health check port must be between 1 and 65535"
  }
}

variable "envoy_upstream_port" {
  description = "Port for Envoy to forward traffic to upstream (e.g., Internal ALB/Istio)"
  type        = number
  default     = 80

  validation {
    condition     = var.envoy_upstream_port >= 1 && var.envoy_upstream_port <= 65535
    error_message = "Envoy upstream port must be between 1 and 65535"
  }
}

# =========================================================================
# SSL/TLS Configuration
# =========================================================================

variable "enable_https_listener" {
  description = "Enable HTTPS listener on port 443 with SSL/TLS termination"
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS listener (required if enable_https_listener = true)"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_http_to_https_redirect" {
  description = "Enable automatic redirect from HTTP to HTTPS (requires enable_https_listener = true)"
  type        = bool
  default     = false
}

# =========================================================================
# Advanced Listener Rules Configuration
# =========================================================================

variable "listener_rules" {
  description = "Advanced listener rules for header-based routing, path-based routing, etc."
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
  description = "Enable AWS WAF WebACL association with ALB"
  type        = bool
  default     = false
}

variable "waf_web_acl_arn" {
  description = "ARN of AWS WAFv2 WebACL to associate with ALB (required if enable_waf = true)"
  type        = string
  default     = null
}

variable "ami_id" {
  description = "AMI ID for Envoy instances (ignored if use_existing_launch_template = true)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for Envoy proxy (ignored if use_existing_launch_template = true)"
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
  description = "SSH key pair name (ignored if generate_ssh_key=true)"
  type        = string
  default     = null
}

variable "generate_ssh_key" {
  description = "Whether to generate SSH key pair automatically. Note: Private key is NOT saved. Use SSM Session Manager for access."
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

variable "custom_userdata" {
  description = "Custom userdata script for Envoy instances. This should be environment-specific and loaded from the live layer (e.g., file(\"$${path.module}/templates/userdata.sh\"))"
  type        = string
}

variable "envoy_config_template" {
  description = <<-EOT
    Envoy configuration template content. This is environment-specific and flexible:
    - Load from file: file("$${path.module}/config/my-envoy-config.yaml")
    - Load from any path: file("/path/to/envoy.yaml")
    - Provide inline: "admin: { ... }"
    - Use try() for optional: try(file("$${path.module}/config/envoy.yaml"), "")
  EOT
  type        = string
  default     = ""
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

# =========================================================================
# Spot Instance Configuration
# =========================================================================

variable "enable_spot_instances" {
  description = "Enable mixed instances policy with spot instances for cost optimization"
  type        = bool
  default     = false
}

variable "spot_instance_percentage" {
  description = "Percentage of spot instances in the ASG (0-100). Remaining will be on-demand."
  type        = number
  default     = 50

  validation {
    condition     = var.spot_instance_percentage >= 0 && var.spot_instance_percentage <= 100
    error_message = "Spot instance percentage must be between 0 and 100"
  }
}

variable "on_demand_base_capacity" {
  description = "Minimum number of on-demand instances to maintain (useful for baseline capacity)"
  type        = number
  default     = 1
}

variable "spot_allocation_strategy" {
  description = "Strategy for allocating spot instances (lowest-price, capacity-optimized, capacity-optimized-prioritized)"
  type        = string
  default     = "capacity-optimized"

  validation {
    condition     = contains(["lowest-price", "capacity-optimized", "capacity-optimized-prioritized"], var.spot_allocation_strategy)
    error_message = "Spot allocation strategy must be one of: lowest-price, capacity-optimized, capacity-optimized-prioritized"
  }
}

variable "on_demand_allocation_strategy" {
  description = "Strategy for allocating on-demand instances (prioritized)"
  type        = string
  default     = "prioritized"
}

variable "enable_capacity_rebalance" {
  description = "Enable capacity rebalancing for spot instances (launches replacement before termination)"
  type        = bool
  default     = false
}

# =========================================================================
# ASG Advanced Configuration
# =========================================================================

variable "termination_policies" {
  description = "List of policies to use when selecting instances to terminate (OldestLaunchTemplate, OldestInstance, Default, etc.)"
  type        = list(string)
  default     = ["OldestLaunchTemplate", "OldestInstance", "Default"]
}

variable "max_instance_lifetime" {
  description = "Maximum lifetime of instances in seconds (0 = no limit, min 86400 = 24 hours)"
  type        = number
  default     = 0

  validation {
    condition     = var.max_instance_lifetime == 0 || var.max_instance_lifetime >= 86400
    error_message = "Maximum instance lifetime must be 0 (disabled) or at least 86400 seconds (24 hours)"
  }
}

variable "create_logs_bucket" {
  description = "Whether to create a new S3 bucket for logs (if false, use existing bucket)"
  type        = bool
  default     = true
}

variable "logs_bucket_name" {
  description = "Name of existing S3 bucket for logs (required if create_logs_bucket=false)"
  type        = string
  default     = ""
}

variable "logs_bucket_arn" {
  description = "ARN of existing S3 bucket for logs (required if create_logs_bucket=false)"
  type        = string
  default     = ""
}

variable "create_config_bucket" {
  description = "Whether to create a new S3 bucket for configuration files (if false, use existing bucket)"
  type        = bool
  default     = false
}

variable "config_bucket_name" {
  description = "Name of S3 bucket containing Envoy configuration files (required if create_config_bucket=false)"
  type        = string
  default     = ""
}

variable "config_bucket_arn" {
  description = "ARN of S3 bucket containing Envoy configuration files (required if create_config_bucket=false)"
  type        = string
  default     = ""
}

variable "upload_config_to_s3" {
  description = "Whether to upload config files from local directory to S3"
  type        = bool
  default     = false
}

variable "config_files_source_path" {
  description = "Local path to envoy config files to upload to S3 (only used if upload_config_to_s3=true)"
  type        = string
  default     = "./config"
}

variable "envoy_config_filename" {
  description = <<-EOT
    Name of the main Envoy config file (relative to config_files_source_path).
    This file will receive template variable substitution when uploaded to S3.
    Different environments can use different filenames:
    - Dev: "envoy.yaml" or "envoy-dev.yaml"
    - Staging: "envoy-staging.yaml"
    - Production: "envoy-prod.yaml" or "proxy-config.yaml"
  EOT
  type        = string
  default     = "envoy.yaml"
}

variable "hyperswitch_cloudfront_dns" {
  description = "CloudFront distribution DNS for Hyperswitch (for envoy.yaml templating)"
  type        = string
  default     = ""
}

variable "internal_loadbalancer_dns" {
  description = "Internal load balancer DNS (for envoy.yaml templating)"
  type        = string
  default     = ""
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

variable "create_lb" {
  description = "Whether to create a new Load Balancer"
  type        = bool
  default     = true
}

variable "create_target_group" {
  description = "Whether to create a new target group"
  type        = bool
  default     = true
}

variable "target_group_protocol" {
  description = "Protocol for target group (HTTP or HTTPS)"
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.target_group_protocol)
    error_message = "Target group protocol must be either HTTP or HTTPS"
  }
}

# =========================================================================
# VPC Endpoint Configuration
# =========================================================================

variable "s3_vpc_endpoint_prefix_list_id" {
  description = "Prefix list ID for S3 VPC endpoint (e.g., pl-6ea54007). If not provided, will use 0.0.0.0/0 for S3 access."
  type        = string
  default     = null
}

variable "existing_lb_arn" {
  description = "ARN of existing load balancer (required if create_lb=false)"
  type        = string
  default     = null
  validation {
    condition     = var.create_lb == true || var.existing_lb_arn != null
    error_message = "existing_lb_arn must be provided when create_lb is false"
  }
}

variable "existing_lb_security_group_id" {
  description = "Security group ID of existing load balancer (required if create_lb=false)"
  type        = string
  default     = null
  validation {
    condition     = var.create_lb == true || var.existing_lb_security_group_id != null
    error_message = "existing_lb_security_group_id must be provided when create_lb is false"
  }
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

# =========================================================================
# Auto Scaling Policies Configuration
# =========================================================================
variable "enable_autoscaling" {
  description = "Enable auto-scaling policies for the ASG based on CPU and memory metrics"
  type        = bool
  default     = false
}

variable "scaling_policies" {
  description = "Configuration for auto-scaling policies using built-in AWS metrics"
  type = object({
    # CPU-based target tracking
    cpu_target_tracking = optional(object({
      enabled      = optional(bool, false)
      target_value = optional(number, 70.0) # Target CPU utilization %
    }), {})

    # Memory-based target tracking (requires CloudWatch agent on instances)
    memory_target_tracking = optional(object({
      enabled      = optional(bool, false)
      target_value = optional(number, 70.0) # Target Memory utilization %
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

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
