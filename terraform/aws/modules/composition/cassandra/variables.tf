# ============================================================================
# Environment & Project Configuration
# ============================================================================
variable "environment" {
  description = "Environment name (dev/integ/prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = null
}

# ============================================================================
# Network Configuration
# ============================================================================
variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Cassandra instances and ENIs"
  type        = string
}

variable "additional_subnet_ids" {
  description = "Additional subnet IDs for multi-AZ deployment (optional)"
  type        = list(string)
  default     = []
}

# ============================================================================
# Cassandra Cluster Configuration
# ============================================================================
variable "cluster_name" {
  description = "Cassandra cluster name"
  type        = string
  default     = "cassandra-hyperswitch"
}

variable "node_count" {
  description = "Number of Cassandra nodes to create"
  type        = number
  default     = 3
  validation {
    condition     = var.node_count >= 1
    error_message = "Node count must be at least 1"
  }
}

variable "replication_factor" {
  description = "Cassandra replication factor"
  type        = number
  default     = 3
  validation {
    condition     = var.replication_factor >= 1
    error_message = "Replication factor must be at least 1"
  }
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

# ============================================================================
# Instance Configuration
# ============================================================================
variable "ami_id" {
  description = "AMI ID for Cassandra instances (ARM-based AMI recommended for m7g instances)"
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

variable "ebs_device_name" {
  description = "Device name for the additional EBS volume"
  type        = string
  default     = "/dev/sdh"
}

# ============================================================================
# SSH Key Configuration
# ============================================================================
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

# ============================================================================
# Security Configuration
# ============================================================================
variable "cassandra_ports" {
  description = "Cassandra service ports to open within the cluster"
  type = object({
    storage     = optional(number, 7000) # Inter-node communication
    storage_ssl = optional(number, 7001) # SSL inter-node communication
    jmx         = optional(number, 7199) # JMX monitoring
    native      = optional(number, 9042) # CQL native transport
    thrift      = optional(number, 9160) # Thrift client (legacy)
  })
  default = {}
}

# ============================================================================
# Seed Discovery Configuration
# ============================================================================
variable "seeds_url" {
  description = "URL of the seed discovery API (Lambda/API Gateway endpoint) that returns seed node IPs. If not provided, a Lambda and API Gateway will be created automatically."
  type        = string
  default     = null
}

variable "create_seed_discovery" {
  description = "Whether to create the seed discovery Lambda and API Gateway. Defaults to true if seeds_url is not provided."
  type        = bool
  default     = true
}

variable "seed_discovery_lambda_source_path" {
  description = "Path to the seed discovery Lambda function source file. Required when create_seed_discovery is true and seeds_url is not provided."
  type        = string
  default     = null

  validation {
    condition     = !(var.create_seed_discovery && var.seeds_url == null) || var.seed_discovery_lambda_source_path != null
    error_message = "seed_discovery_lambda_source_path is required when create_seed_discovery is true and seeds_url is not provided."
  }
}

variable "api_gateway_vpce_id" {
  description = "VPC Endpoint ID for the API Gateway (execute-api). Required for PRIVATE API Gateway endpoint type."
  type        = string
  default     = null
}

variable "vpc_endpoint_security_group_id" {
  description = "Security group ID for VPC endpoints. Required to allow HTTPS access from Cassandra to VPC endpoints (EC2 API)."
  type        = string
  default     = null
}

# ============================================================================
# Monitoring & Logging
# ============================================================================
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "KMS key ID for CloudWatch log group encryption"
  type        = string
  default     = null
}

# ============================================================================
# Tag Configuration
# ============================================================================
variable "cluster_tag_name" {
  description = "Tag name used to identify Cassandra cluster instances for seed discovery"
  type        = string
  default     = "cluster"
}

variable "cluster_tag_value" {
  description = "Tag value used to identify Cassandra cluster instances for seed discovery"
  type        = string
  default     = "cassandra-cluster"
}

variable "eni_tag_name" {
  description = "Tag name used to identify Cassandra ENIs"
  type        = string
  default     = "cluster"
}

variable "eni_tag_value" {
  description = "Tag value used to identify Cassandra ENIs"
  type        = string
  default     = "cassandra"
}

# ============================================================================
# IMDSv2 Configuration
# ============================================================================
variable "metadata_http_tokens" {
  description = "IMDSv2 setting for EC2 instances - 'required' for IMDSv2 only, 'optional' for IMDSv1 and IMDSv2"
  type        = string
  default     = "required"
  validation {
    condition     = contains(["required", "optional"], var.metadata_http_tokens)
    error_message = "metadata_http_tokens must be either 'required' or 'optional'"
  }
}

# ============================================================================
# Tags
# ============================================================================
variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
