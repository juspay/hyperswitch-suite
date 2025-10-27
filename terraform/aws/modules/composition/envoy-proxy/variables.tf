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

# NOTE: eks_security_group_id is NOT needed for Envoy proxy
# Traffic flow: CloudFront → External ALB → Envoy → Internal ALB → EKS
# EKS does not initiate connections to Envoy, so EKS SG is not required
# (This is different from Squid proxy where EKS → Squid → Internet)
# Variable kept for backward compatibility but not used anywhere
variable "eks_security_group_id" {
  description = "DEPRECATED: Not used. Kept for backward compatibility only."
  type        = string
  default     = null
}

variable "envoy_admin_port" {
  description = "Port for Envoy admin interface (localhost only, not exposed externally)"
  type        = number
  default     = 9901
}

variable "envoy_listener_port" {
  description = "Port for Envoy listener"
  type        = number
  default     = 10000
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

variable "existing_iam_instance_profile_name" {
  description = "Name of existing IAM instance profile to use (only if create_iam_role = false)"
  type        = string
  default     = null
}

variable "custom_userdata" {
  description = "Custom userdata script for Envoy instances"
  type        = string
}

variable "envoy_config_template" {
  description = "Envoy configuration template (envoy.yaml content)"
  type        = string
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

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
