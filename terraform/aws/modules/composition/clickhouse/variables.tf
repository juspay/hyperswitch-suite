# =========================================================================
# Environment & Project Configuration
# =========================================================================

variable "environment" {
  description = "Environment name (dev/integ/prod/sandbox)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

# =========================================================================
# Network Configuration
# =========================================================================

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "keeper_subnet_id" {
  description = "Subnet ID for Clickhouse keeper instances and ENIs"
  type        = string
}

variable "server_subnet_id" {
  description = "Subnet ID for Clickhouse server instances and ENIs"
  type        = string
}

variable "vpc_endpoint_security_group_id" {
  description = "Security group ID of VPC endpoints (for EC2 Metadata). If provided, HTTPS rules will be created."
  type        = string
  default     = null
}

# =========================================================================
# Keeper Configuration
# =========================================================================

variable "keeper_count" {
  description = "Number of Clickhouse keeper nodes to create (can be 0 if using external keeper)"
  type        = number
  default     = 3
  validation {
    condition     = var.keeper_count >= 0
    error_message = "Keeper count must be 0 or greater"
  }
}

variable "keeper_ami_id" {
  description = "AMI ID for Clickhouse keeper instances"
  type        = string
}

variable "keeper_instance_type" {
  description = "EC2 instance type for Clickhouse keepers"
  type        = string
  default     = "c7g.medium"
}

variable "keeper_root_volume_size" {
  description = "Size of the keeper root EBS volume in GB"
  type        = number
  default     = 30
}

variable "keeper_root_volume_type" {
  description = "Type of the keeper root EBS volume"
  type        = string
  default     = "gp3"
}

variable "keeper_data_volume_size" {
  description = "Size of the additional EBS volume in GB for Clickhouse keeper data"
  type        = number
  default     = 10
}

variable "keeper_data_volume_type" {
  description = "Type of the additional EBS volume for keeper data"
  type        = string
  default     = "gp3"
}

variable "keeper_data_device_name" {
  description = "Device name for the keeper data EBS volume"
  type        = string
  default     = "/dev/sdb"
}

variable "keeper_data2_volume_size" {
  description = "Size of the second additional EBS volume in GB for Clickhouse keeper"
  type        = number
  default     = 10
}

variable "keeper_data2_volume_type" {
  description = "Type of the second additional EBS volume for keeper"
  type        = string
  default     = "gp3"
}

variable "keeper_data2_device_name" {
  description = "Device name for the keeper second data EBS volume"
  type        = string
  default     = "/dev/sdc"
}

# =========================================================================
# Server Configuration
# =========================================================================

variable "server_count" {
  description = "Number of Clickhouse server nodes to create"
  type        = number
  default     = 2
  validation {
    condition     = var.server_count >= 1
    error_message = "Server count must be at least 1"
  }
}

variable "server_ami_id" {
  description = "AMI ID for Clickhouse server instances"
  type        = string
}

variable "server_instance_type" {
  description = "EC2 instance type for Clickhouse servers"
  type        = string
  default     = "r7g.large"
}

variable "server_root_volume_size" {
  description = "Size of the server root EBS volume in GB"
  type        = number
  default     = 200
}

variable "server_root_volume_type" {
  description = "Type of the server root EBS volume"
  type        = string
  default     = "gp3"
}

variable "server_data_volume_size" {
  description = "Size of the additional EBS volume in GB for Clickhouse server data"
  type        = number
  default     = 20
}

variable "server_data_volume_type" {
  description = "Type of the additional EBS volume for server data"
  type        = string
  default     = "gp3"
}

variable "server_data_device_name" {
  description = "Device name for the server data EBS volume"
  type        = string
  default     = "/dev/sdb"
}

variable "server_data2_volume_size" {
  description = "Size of the second additional EBS volume in GB for Clickhouse server"
  type        = number
  default     = 20
}

variable "server_data2_volume_type" {
  description = "Type of the second additional EBS volume for server"
  type        = string
  default     = "gp3"
}

variable "server_data2_device_name" {
  description = "Device name for the server second data EBS volume"
  type        = string
  default     = "/dev/sdc"
}

# =========================================================================
# Load Balancer Configuration
# =========================================================================

variable "clickhouse_port" {
  description = "Port for Clickhouse HTTP interface"
  type        = number
  default     = 8123
}

variable "alb_subnet_ids" {
  description = "List of subnet IDs for the Application Load Balancer. At least two subnets in two different Availability Zones are required."
  type        = list(string)

  validation {
    condition     = length(var.alb_subnet_ids) >= 2
    error_message = "At least two subnets in two different Availability Zones must be specified for the ALB."
  }
}

variable "alb_listeners" {
  description = "ALB listener configurations for the Application Load Balancer"
  type = map(object({
    port             = number
    protocol         = string
    target_group_arn = optional(string)
    certificate_arn  = optional(string)
  }))
  default = {
    "http" = {
      port     = 80
      protocol = "HTTP"
    }
  }
  validation {
    condition = alltrue([
      for key, listener in var.alb_listeners :
      contains(["HTTP", "HTTPS"], listener.protocol)
    ])
    error_message = "Listener protocol must be one of: HTTP, HTTPS"
  }
}

# =========================================================================
# Tags
# =========================================================================

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "keeper_user_data_template" {
  description = "Path to the keeper user data template file. If provided, the template will be processed with keeper_ips and server_ips variables."
  type        = string
  default     = null
}

variable "server_user_data_template" {
  description = "Path to the server user data template file. If provided, the template will be processed with keeper_ips and server_ips variables."
  type        = string
  default     = null
}

# =========================================================================
# SSH Key Configuration
# =========================================================================

variable "key_name" {
  description = "SSH key pair name. Required if create_key_pair is false."
  type        = string
  default     = null
}

variable "create_key_pair" {
  description = "Whether to create a new SSH key pair"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key material for creating new SSH key pair. If not provided when create_key_pair is true, a key pair will be auto-generated and stored in SSM"
  type        = string
  default     = null
}

variable "metadata_http_tokens" {
  description = "IMDSv2 setting for EC2 instances - 'required' for IMDSv2 only, 'optional' for IMDSv1 and IMDSv2"
  type        = string
  default     = "required"
  validation {
    condition     = contains(["required", "optional"], var.metadata_http_tokens)
    error_message = "metadata_http_tokens must be either 'required' or 'optional'"
  }
}

# =========================================================================
# IAM Configuration
# =========================================================================

variable "iam_inline_policies" {
  description = "Map of inline policy name to policy JSON. If not provided, uses default permissions."
  type        = map(string)
  default     = {}
}

variable "iam_managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}