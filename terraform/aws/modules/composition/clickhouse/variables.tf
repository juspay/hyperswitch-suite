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

# =========================================================================
# User Data Configuration
# =========================================================================

variable "cluster_name" {
  description = "Name of the Clickhouse cluster"
  type        = string
  default     = "hyperswitch-clickhouse-ec2"
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

# =========================================================================
# Tags
# =========================================================================

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}