variable "environment" {
  description = "Environment name (e.g., dev, integ, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hyperswitch"
}

variable "vpc_id" {
  description = "VPC ID where Clickhouse will be deployed"
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

variable "keeper_count" {
  description = "Number of Clickhouse keeper nodes to create"
  type        = number
  default     = 3
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

variable "server_count" {
  description = "Number of Clickhouse server nodes to create"
  type        = number
  default     = 2
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

variable "create_key_pair" {
  description = "Whether to create a new SSH key pair"
  type        = bool
  default     = true
}

variable "public_key" {
  description = "Public key material for creating new SSH key pair. If not provided, a key will be auto-generated and stored in SSM"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
