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
  description = "VPC ID where Kafka will be deployed"
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

variable "broker_count" {
  description = "Number of Kafka broker nodes to create"
  type        = number
  default     = 3
}

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
