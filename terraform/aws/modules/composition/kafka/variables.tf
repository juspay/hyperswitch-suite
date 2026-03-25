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

variable "broker_subnet_id" {
  description = "Subnet ID for Kafka broker instances and ENIs"
  type        = string
}

variable "controller_subnet_id" {
  description = "Subnet ID for Kafka controller instances and ENIs"
  type        = string
}

variable "vpc_endpoint_security_group_id" {
  description = "Security group ID of VPC endpoints for HTTPS egress from Kafka instances"
  type        = string
  default     = null
}

# =========================================================================
# Kafka Cluster Configuration
# =========================================================================

variable "broker_count" {
  description = "Number of Kafka broker nodes to create"
  type        = number
  default     = 3
  validation {
    condition     = var.broker_count >= 1
    error_message = "Broker count must be at least 1"
  }
}

# =========================================================================
# Broker Instance Configuration
# =========================================================================

variable "broker_ami_id" {
  description = "AMI ID for Kafka broker instances"
  type        = string
}

variable "broker_instance_type" {
  description = "EC2 instance type for Kafka brokers"
  type        = string
  default     = "t4g.medium"
}

variable "broker_root_volume_size" {
  description = "Size of the broker root EBS volume in GB"
  type        = number
  default     = 30
}

variable "broker_root_volume_type" {
  description = "Type of the broker root EBS volume"
  type        = string
  default     = "gp3"
}

variable "broker_data_volume_size" {
  description = "Size of the additional EBS volume in GB for Kafka broker data"
  type        = number
  default     = 10
}

variable "broker_data_volume_type" {
  description = "Type of the additional EBS volume for broker data"
  type        = string
  default     = "gp3"
}

variable "broker_data_device_name" {
  description = "Device name for the broker data EBS volume"
  type        = string
  default     = "/dev/sdb"
}

# =========================================================================
# Controller Instance Configuration
# =========================================================================

variable "controller_ami_id" {
  description = "AMI ID for Kafka controller instances"
  type        = string
}

variable "controller_instance_type" {
  description = "EC2 instance type for Kafka controllers"
  type        = string
  default     = "c7g.medium"
}

variable "controller_root_volume_size" {
  description = "Size of the controller root EBS volume in GB"
  type        = number
  default     = 30
}

variable "controller_root_volume_type" {
  description = "Type of the controller root EBS volume"
  type        = string
  default     = "gp3"
}

variable "controller_metadata_volume_size" {
  description = "Size of the additional EBS volume in GB for Kafka controller metadata"
  type        = number
  default     = 10
}

variable "controller_metadata_volume_type" {
  description = "Type of the additional EBS volume for controller metadata"
  type        = string
  default     = "gp3"
}

variable "controller_metadata_device_name" {
  description = "Device name for the controller metadata EBS volume"
  type        = string
  default     = "/dev/sdb"
}

# =========================================================================
# Kafka Configuration
# =========================================================================

variable "broker_user_data_override" {
  description = "Custom user data for broker instances. If provided, this will be used instead of the default JSON user data."
  type        = string
  default     = null
}

variable "controller_user_data_override" {
  description = "Custom user data for controller instance. If provided, this will be used instead of the default JSON user data."
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