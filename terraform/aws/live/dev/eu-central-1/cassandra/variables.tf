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
  description = "VPC ID where Cassandra will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Cassandra instances and ENIs"
  type        = string
}

variable "cluster_name" {
  description = "Cassandra cluster name"
  type        = string
  default     = "cassandra-hyperswitch"
}

variable "node_count" {
  description = "Number of Cassandra nodes to create"
  type        = number
  default     = 3
}

variable "replication_factor" {
  description = "Cassandra replication factor"
  type        = number
  default     = 3
}

variable "idle_timeout" {
  description = "Cassandra idle timeout"
  type        = string
  default     = "3600000ms"
}

variable "default_config_path" {
  description = "Default Cassandra configuration path/profile"
  type        = string
  default     = "ReadWriteHeavy"
}

variable "ami_id" {
  description = "AMI ID for Cassandra instances (ARM-based AMI for m7g instances)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Cassandra nodes"
  type        = string
  default     = "m7g.large"
}

variable "ebs_volume_size" {
  description = "Size of the additional EBS volume in GB for Cassandra data"
  type        = number
  default     = 100
}

variable "ebs_volume_type" {
  description = "Type of the additional EBS volume"
  type        = string
  default     = "gp3"
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

variable "seed_discovery_lambda_source" {
  description = "Source code for the seed discovery Lambda function"
  type        = string
}

variable "api_gateway_vpce_id" {
  description = "VPC Endpoint ID for the API Gateway (execute-api). Required for PRIVATE API Gateway endpoint type"
  type        = string
}

variable "cassandra_ports" {
  description = "Cassandra service ports to open within the cluster"
  type = object({
    storage     = optional(number, 7000)
    storage_ssl = optional(number, 7001)
    jmx         = optional(number, 7199)
    native      = optional(number, 9042)
    thrift      = optional(number, 9160)
  })
  default = {}
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
