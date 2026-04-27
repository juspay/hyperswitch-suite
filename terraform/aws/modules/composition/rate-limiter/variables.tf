# =========================================================================
# REQUIRED VARIABLES
# =========================================================================

variable "environment" {
  description = "Environment name (e.g., dev, integ, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "asg_subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

# =========================================================================
# OPTIONAL VARIABLES - General
# =========================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}

# =========================================================================
# OPTIONAL VARIABLES - NLB
# =========================================================================

variable "create_nlb" {
  description = "Whether to create the Network Load Balancer"
  type        = bool
  default     = true
}

variable "internal" {
  description = "Whether the NLB is internal or external"
  type        = bool
  default     = false
}

variable "nlb_subnet_ids" {
  description = "List of subnet IDs for the NLB (required if create_nlb is true)"
  type        = list(string)
  default     = []
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the NLB"
  type        = bool
  default     = false
}

variable "access_logs" {
  description = "Access logs configuration for NLB"
  type = object({
    enabled = optional(bool, false)
    bucket  = optional(string, null)
    prefix  = optional(string, null)
  })
  default = {
    enabled = false
  }
}

variable "listeners" {
  description = "Map of listener configurations for NLB"
  type = map(object({
    port            = number
    protocol        = string
    certificate_arn = optional(string, null)
    alpn_policy     = optional(string, null)
    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
  }))
  default = {
    "tcp" = {
      port     = 80
      protocol = "TCP"
    }
  }
}

variable "nlb_ingress_rules" {
  description = "Map of ingress rules for NLB security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {
    "tcp" = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow TCP traffic"
    }
  }
}

# =========================================================================
# OPTIONAL VARIABLES - Target Group
# =========================================================================

variable "traffic_port" {
  description = "Port on which the rate limiter application listens"
  type        = number
  default     = 8091
}

variable "target_group_protocol" {
  description = "Protocol for the target group (TCP, TLS, UDP, TCP_UDP)"
  type        = string
  default     = "TCP"
}

variable "deregistration_delay" {
  description = "Time to wait before deregistering targets"
  type        = number
  default     = 300
}

variable "health_check_port" {
  description = "Port for health checks (defaults to traffic_port if not set)"
  type        = number
  default     = null
}

variable "health_check_protocol" {
  description = "Protocol for health checks (TCP, HTTP, HTTPS)"
  type        = string
  default     = "TCP"
}

variable "health_check_path" {
  description = "Path for HTTP/HTTPS health checks"
  type        = string
  default     = "/health"
}

variable "health_check_matcher" {
  description = "HTTP codes to expect for health check success"
  type        = string
  default     = "200"
}

variable "health_check_interval" {
  description = "Interval between health checks (seconds)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout for health checks (seconds)"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Number of consecutive successes for healthy status"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Number of consecutive failures for unhealthy status"
  type        = number
  default     = 3
}

# =========================================================================
# OPTIONAL VARIABLES - Auto Scaling Group
# =========================================================================

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 10
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "ELB"
}

variable "health_check_grace_period" {
  description = "Grace period for health checks (seconds)"
  type        = number
  default     = 300
}

variable "default_cooldown" {
  description = "Cooldown period between scaling activities (seconds)"
  type        = number
  default     = 300
}

variable "termination_policies" {
  description = "List of termination policies"
  type        = list(string)
  default     = ["Default"]
}

variable "max_instance_lifetime" {
  description = "Maximum lifetime of instances (seconds)"
  type        = number
  default     = 0
}

variable "enable_capacity_rebalance" {
  description = "Enable capacity rebalancing for Spot instances"
  type        = bool
  default     = false
}

variable "protect_from_scale_in" {
  description = "Protect instances from scale in"
  type        = bool
  default     = false
}

# =========================================================================
# OPTIONAL VARIABLES - Launch Template
# =========================================================================

variable "use_existing_launch_template" {
  description = "Whether to use an existing launch template"
  type        = bool
  default     = false
}

variable "existing_launch_template_id" {
  description = "ID of existing launch template (if use_existing_launch_template is true)"
  type        = string
  default     = null
}

variable "existing_launch_template_version" {
  description = "Version of existing launch template"
  type        = string
  default     = "$Latest"
}

variable "ami_id" {
  description = "AMI ID for instances (defaults to latest Amazon Linux 2023)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type for ASG instances"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script (defaults to template). If provided, this overrides the templated userdata."
  type        = string
  default     = null
}

# =========================================================================
# OPTIONAL VARIABLES - Userdata Configuration
# =========================================================================

variable "userdata_config" {
  description = "Configuration for the userdata script. All values are optional and have sensible defaults."
  type = object({
    # Wazuh settings
    update_wazuh       = optional(string, "Disable")
    wazuh_manager_addr = optional(string, "NA")
    wazuh_worker_addr  = optional(string, "NA")
    wazuh_group        = optional(string, "NA")
    wazuh_tag          = optional(string, "NA")

    # Stack and logging settings
    stack_svc       = optional(string, "ratelimiter")
    syslog_rotation = optional(string, "enable")

    # User and access settings
    sudo_user_list   = optional(string, "")
    normal_user_list = optional(string, "NA")
    ssh_service      = optional(string, "SSM")

    # Network settings
    additional_inbound_ports  = optional(string, "")
    additional_outbound_ports = optional(string, "")
  })
  default = {}
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "enable_ebs_block_device" {
  description = "Enable EBS block device mapping"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Size of root volume (GiB)"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
}

variable "ebs_encrypted" {
  description = "Encrypt EBS volumes"
  type        = bool
  default     = true
}

variable "ebs_kms_key_id" {
  description = "KMS key ID for EBS encryption"
  type        = string
  default     = null
}

# IMDS Settings
variable "imds_http_endpoint" {
  description = "IMDS HTTP endpoint setting (enabled/disabled)"
  type        = string
  default     = "enabled"
}

variable "imds_http_tokens" {
  description = "IMDS HTTP tokens setting (optional/required)"
  type        = string
  default     = "required"
}

variable "imds_http_put_response_hop_limit" {
  description = "IMDS HTTP PUT response hop limit"
  type        = number
  default     = 1
}

variable "imds_instance_metadata_tags" {
  description = "Enable IMDS instance metadata tags"
  type        = string
  default     = "disabled"
}

# =========================================================================
# OPTIONAL VARIABLES - Spot Instances
# =========================================================================

variable "enable_spot_instances" {
  description = "Enable Spot instances in mixed instances policy"
  type        = bool
  default     = false
}

variable "on_demand_base_capacity" {
  description = "Base capacity of On-Demand instances"
  type        = number
  default     = 0
}

variable "spot_instance_percentage" {
  description = "Percentage of Spot instances above base capacity"
  type        = number
  default     = 100
}

variable "spot_allocation_strategy" {
  description = "Spot allocation strategy (lowest-price, capacity-optimized)"
  type        = string
  default     = "capacity-optimized"
}

variable "spot_instance_types" {
  description = "List of override instance types for Spot"
  type = list(object({
    instance_type = string
  }))
  default = []
}

# =========================================================================
# OPTIONAL VARIABLES - IAM
# =========================================================================

variable "create_iam_role" {
  description = "Whether to create a new IAM role"
  type        = bool
  default     = true
}

variable "create_instance_profile" {
  description = "Whether to create an instance profile for existing role"
  type        = bool
  default     = false
}

variable "iam_role_name" {
  description = "Name of existing IAM role (if create_iam_role is false)"
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "Name of existing instance profile"
  type        = string
  default     = null
}

variable "iam_managed_policy_arns" {
  description = "List of managed policy ARNs to attach to IAM role"
  type        = list(string)
  default     = []
}

variable "iam_inline_policy_statements" {
  description = "List of inline policy statements for IAM role"
  type        = list(any)
  default     = []
}

# =========================================================================
# OPTIONAL VARIABLES - Security Group Rules
# =========================================================================

variable "asg_ingress_rules" {
  description = "Additional ingress rules for ASG security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {}
}

variable "asg_egress_rules" {
  description = "Egress rules for ASG security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {
    "all" = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  }
}

# =========================================================================
# OPTIONAL VARIABLES - Auto Scaling Policies
# =========================================================================

variable "enable_autoscaling" {
  description = "Enable auto scaling policies"
  type        = bool
  default     = false
}

variable "scaling_policies" {
  description = "Scaling policy configuration"
  type = object({
    cpu_target_tracking = optional(object({
      enabled      = optional(bool, false)
      target_value = optional(number, 70)
      }), {
      enabled      = false
      target_value = 70
    })
    request_count_target_tracking = optional(object({
      enabled      = optional(bool, false)
      target_value = optional(number, 1000)
      }), {
      enabled      = false
      target_value = 1000
    })
  })
  default = {
    cpu_target_tracking = {
      enabled      = false
      target_value = 70
    }
    request_count_target_tracking = {
      enabled      = false
      target_value = 1000
    }
  }
}

# =========================================================================
# OPTIONAL VARIABLES - S3 Config Bucket
# =========================================================================

variable "create_config_bucket" {
  description = "Whether to create a new S3 bucket for rate limiter configuration files"
  type        = bool
  default     = true
}

variable "config_bucket_name" {
  description = "Name of existing S3 bucket containing rate limiter configuration files (required if create_config_bucket=false)"
  type        = string
  default     = ""
}

variable "config_bucket_arn" {
  description = "ARN of existing S3 bucket containing rate limiter configuration files (required if create_config_bucket=false)"
  type        = string
  default     = ""
}

variable "upload_config_to_s3" {
  description = "Whether to upload config files from local directory to S3"
  type        = bool
  default     = true
}

variable "config_files_source_path" {
  description = "Local path to rate limiter config files to upload to S3 (only used if upload_config_to_s3=true)"
  type        = string
  default     = "./config"
}

variable "ratelimit_env_config_filename" {
  description = "Name of the rate limiter environment config file (relative to config_files_source_path)"
  type        = string
  default     = "ratelimit-env.conf"
}

variable "ratelimit_descriptor_filename" {
  description = "Name of the rate limiter descriptor file (relative to config_files_source_path)"
  type        = string
  default     = "ratelimits.yaml"
}

# =========================================================================
# OPTIONAL VARIABLES - CloudWatch Logs
# =========================================================================

variable "create_log_group" {
  description = "Whether to create CloudWatch log group"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period"
  }
}

# =========================================================================
# OPTIONAL VARIABLES - ElastiCache
# =========================================================================

variable "elasticache_config" {
  description = "ElastiCache configuration for rate limiter."
  type = object({
    enabled                     = optional(bool, true)
    subnet_ids                  = optional(list(string), [])
    engine                      = optional(string, "redis")
    engine_version              = optional(string, "7.0")
    parameter_group_name        = optional(string, "default.redis7")
    port                        = optional(number, 6379)
    node_type                   = optional(string, "cache.t3.small")
    num_cache_clusters          = optional(number, 2)
    num_node_groups             = optional(number, null)
    replicas_per_node_group     = optional(number, null)
    cluster_mode                = optional(string, "disabled")
    automatic_failover_enabled  = optional(bool, true)
    multi_az_enabled            = optional(bool, true)
    at_rest_encryption_enabled  = optional(bool, true)
    transit_encryption_enabled  = optional(bool, false)
    auth_token                  = optional(string, null)
    create_subnet_group         = optional(bool, true)
    subnet_group_name           = optional(string, null)
    create_security_group       = optional(bool, true)
    existing_security_group_ids = optional(list(string), [])
    maintenance_window          = optional(string, "sun:05:00-sun:06:00")
    snapshot_window             = optional(string, "03:00-05:00")
    snapshot_retention_limit    = optional(number, 1)
    apply_immediately           = optional(bool, false)
  })
  default = {}
}
