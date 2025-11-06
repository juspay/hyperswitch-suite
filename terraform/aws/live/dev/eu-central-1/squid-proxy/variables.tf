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

variable "eks_worker_subnet_cidrs" {
  description = "List of CIDR blocks for EKS worker node subnets (required because NLB preserves source IP)"
  type        = list(string)
  default     = []
}

variable "external_jumpbox_sg_id" {
  description = "Security group ID of external jumpbox for SSH access (optional)"
  type        = string
  default     = null
}

variable "prometheus_sg_id" {
  description = "Security group ID of external Prometheus for metrics scraping (optional)"
  type        = string
  default     = null
}

variable "prometheus_port" {
  description = "Port for Prometheus metrics scraping"
  type        = number
  default     = 9273
}

variable "additional_egress_rules" {
  description = "Additional egress rules for environment-specific requirements (monitoring, security tools, etc.)"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "squid_port" {
  description = "Squid proxy port"
  type        = number
  default     = 3128
}

variable "ami_id" {
  description = "AMI ID for Squid instances (ignored if use_existing_launch_template = true)"
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

variable "configure_root_volume" {
  description = "Whether to explicitly configure root volume. If false, uses AMI defaults (not recommended)"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Root volume size in GB (only used if configure_root_volume=true)"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root volume type (only used if configure_root_volume=true)"
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

variable "listener_rule_priority" {
  description = "Priority for listener rule on existing LB"
  type        = number
  default     = 100
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
# Instance Refresh Configuration
# =========================================================================
variable "enable_instance_refresh" {
  description = "Enable automatic instance refresh when launch template changes"
  type        = bool
  default     = false
}

variable "instance_refresh_preferences" {
  description = "Preferences for instance refresh behavior"
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
# NLB Listener Configuration (TCP and TLS)
# =========================================================================
variable "enable_tcp_listener" {
  description = "Enable TCP listener on the NLB (typically port 80)"
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
}

