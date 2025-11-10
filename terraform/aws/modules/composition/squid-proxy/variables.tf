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

variable "ingress_rules" {
  description = "Ingress rules for ASG security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr        = optional(list(string))
    sg_id       = optional(list(string))
  }))
  default = []

}

variable "egress_rules" {
  description = "Egress rules for ASG security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr        = optional(list(string))
    sg_id       = optional(list(string))
  }))
  default = []

}

variable "squid_port" {
  description = "Port for Squid proxy"
  type        = number
  default     = 3128
}

variable "ami_id" {
  description = "AMI ID for Squid instances (ignored if use_existing_launch_template = true)"
  type        = string
  default     = null
}

variable "custom_userdata" {
  description = "Custom userdata script for Squid instances. Should be base64 encoded or plain text."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Squid proxy (ignored if use_existing_launch_template = true)"
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
  description = "Name of S3 bucket containing Squid configuration files (required if create_config_bucket=false)"
  type        = string
  default     = ""
}

variable "config_bucket_arn" {
  description = "ARN of S3 bucket containing Squid configuration files (required if create_config_bucket=false)"
  type        = string
  default     = ""
}

variable "upload_config_to_s3" {
  description = "Whether to upload config files from local directory to S3"
  type        = bool
  default     = false
}

variable "config_files_source_path" {
  description = "Local path to squid config files to upload to S3 (only used if upload_config_to_s3=true)"
  type        = string
  default     = "./config"
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "configure_root_volume" {
  description = "Whether to explicitly configure root volume. If false, uses AMI defaults (not recommended)"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB (only used if configure_root_volume=true)"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Type of root EBS volume (only used if configure_root_volume=true)"
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

# =========================================================================
# NLB Listener Configuration (TCP and TLS)
# =========================================================================
variable "enable_tcp_listener" {
  description = "Enable TCP listener on the NLB (typically port 80 or 3128)"
  type        = bool
  default     = true
}

variable "tcp_listener_port" {
  description = "Port for TCP listener (if enable_tcp_listener=true)"
  type        = number
  default     = 80
}

variable "enable_tls_listener" {
  description = "Enable TLS listener on port 443 for encrypted proxy connections"
  type        = bool
  default     = false
}

variable "tls_listener_port" {
  description = "Port for TLS listener (if enable_tls_listener=true)"
  type        = number
  default     = 443
}

variable "tls_certificate_arn" {
  description = "ARN of ACM certificate for TLS listener (required if enable_tls_listener=true)"
  type        = string
  default     = null

  validation {
    condition     = var.enable_tls_listener == false || var.tls_certificate_arn != null
    error_message = "tls_certificate_arn must be provided when enable_tls_listener is true"
  }
}

variable "tls_ssl_policy" {
  description = "SSL policy for TLS listener. Use ELBSecurityPolicy-TLS13-1-2-2021-06 for TLS 1.3 + 1.2 support"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "tls_alpn_policy" {
  description = "ALPN policy for TLS listener. Options: None, HTTP2Preferred, HTTP2Only"
  type        = string
  default     = "None"

  validation {
    condition     = contains(["None", "HTTP2Preferred", "HTTP2Only"], var.tls_alpn_policy)
    error_message = "tls_alpn_policy must be one of: None, HTTP2Preferred, HTTP2Only"
  }
}

# =========================================================================
# Instance Refresh Configuration
# =========================================================================
variable "enable_instance_refresh" {
  description = "Enable automatic instance refresh when launch template changes. When enabled, ASG will automatically replace instances with manual checkpoints for validation."
  type        = bool
  default     = false
}

variable "instance_refresh_preferences" {
  description = "Preferences for instance refresh behavior. Defines how instances are replaced during a refresh."
  type = object({
    min_healthy_percentage       = optional(number, 50)
    instance_warmup              = optional(number, 300)
    max_healthy_percentage       = optional(number, 100)
    checkpoint_percentages       = optional(list(number), [50])
    checkpoint_delay             = optional(number, 300)
    scale_in_protected_instances = optional(string, "Ignore")
    standby_instances            = optional(string, "Ignore")
  })
  default = {
    min_healthy_percentage       = 50
    instance_warmup              = 300
    max_healthy_percentage       = 100
    checkpoint_percentages       = [50]
    checkpoint_delay             = 300
    scale_in_protected_instances = "Ignore"
    standby_instances            = "Ignore"
  }
}

variable "instance_refresh_triggers" {
  description = "List of triggers that will start an instance refresh. Note: launch_template changes always trigger refresh automatically."
  type        = list(string)
  default     = []  # Empty - launch_template triggers are automatic
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
