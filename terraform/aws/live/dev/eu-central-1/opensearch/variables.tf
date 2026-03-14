# ============================================================================
# OpenSearch Domain Variables - Dev Environment
# ============================================================================

# ============================================================================
# Environment Variables
# ============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

# ============================================================================
# Domain Configuration
# ============================================================================

variable "domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string
  default     = "hyperswitch-sandbox"
}

variable "engine_version" {
  description = "OpenSearch/Elasticsearch engine version"
  type        = string
  default     = "Elasticsearch_7.10"
}

variable "ip_address_type" {
  description = "IP address type for the endpoint (ipv4 or dualstack)"
  type        = string
  default     = "ipv4"
}

# ============================================================================
# Cluster Configuration
# ============================================================================

variable "instance_type" {
  description = "Instance type for data nodes"
  type        = string
  default     = "r7g.large.search"
}

variable "instance_count" {
  description = "Number of data nodes"
  type        = number
  default     = 1
}

variable "dedicated_master_enabled" {
  description = "Enable dedicated master nodes"
  type        = bool
  default     = false
}

variable "dedicated_master_type" {
  description = "Instance type for dedicated master nodes"
  type        = string
  default     = "c6g.large.search"
}

variable "dedicated_master_count" {
  description = "Number of dedicated master nodes"
  type        = number
  default     = 3
}

variable "zone_awareness_enabled" {
  description = "Enable zone awareness for high availability"
  type        = bool
  default     = false
}

variable "availability_zone_count" {
  description = "Number of availability zones (2 or 3)"
  type        = number
  default     = 2
}

variable "multi_az_with_standby_enabled" {
  description = "Enable Multi-AZ with standby"
  type        = bool
  default     = false
}

variable "warm_enabled" {
  description = "Enable UltraWarm data nodes"
  type        = bool
  default     = false
}

variable "warm_type" {
  description = "Instance type for UltraWarm nodes"
  type        = string
  default     = null
}

variable "warm_count" {
  description = "Number of UltraWarm nodes"
  type        = number
  default     = null
}

# ============================================================================
# EBS Storage Configuration
# ============================================================================

variable "ebs_enabled" {
  description = "Enable EBS volumes for data nodes"
  type        = bool
  default     = true
}

variable "volume_type" {
  description = "EBS volume type (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "volume_size" {
  description = "EBS volume size in GiB"
  type        = number
  default     = 300
}

variable "volume_iops" {
  description = "Provisioned IOPS for EBS volumes"
  type        = number
  default     = 3000
}

variable "volume_throughput" {
  description = "Throughput in MiB/s for gp3 volumes"
  type        = number
  default     = 250
}

# ============================================================================
# VPC Configuration
# ============================================================================

variable "vpc_id" {
  description = "VPC ID where OpenSearch will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for OpenSearch domain"
  type        = list(string)
}

variable "create_security_group" {
  description = "Create a security group for OpenSearch"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description for the security group"
  type        = string
  default     = null
}

variable "existing_security_group_ids" {
  description = "List of existing security group IDs to attach"
  type        = list(string)
  default     = []
}


# ============================================================================
# Security Configuration
# ============================================================================

variable "encrypt_at_rest_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption at rest (null for AWS-managed)"
  type        = string
  default     = null
}

variable "node_to_node_encryption_enabled" {
  description = "Enable node-to-node encryption"
  type        = bool
  default     = true
}

variable "enforce_https" {
  description = "Enforce HTTPS for domain endpoint"
  type        = bool
  default     = true
}

variable "tls_security_policy" {
  description = "TLS security policy"
  type        = string
  default     = "Policy-Min-TLS-1-2-2019-07"
}

# ============================================================================
# Fine-Grained Access Control
# ============================================================================

variable "advanced_security_enabled" {
  description = "Enable fine-grained access control"
  type        = bool
  default     = false
}

variable "internal_user_database_enabled" {
  description = "Enable internal user database"
  type        = bool
  default     = false
}

variable "master_user_arn" {
  description = "ARN of the master user"
  type        = string
  default     = null
}

variable "master_user_name" {
  description = "Username of the master user"
  type        = string
  default     = null
}

variable "master_user_password" {
  description = "Password of the master user"
  type        = string
  default     = null
  sensitive   = true
}

variable "anonymous_auth_enabled" {
  description = "Enable anonymous authentication"
  type        = bool
  default     = false
}

# ============================================================================
# Custom Endpoint
# ============================================================================

variable "custom_endpoint_enabled" {
  description = "Enable custom endpoint"
  type        = bool
  default     = false
}

variable "custom_endpoint" {
  description = "Custom endpoint domain name"
  type        = string
  default     = null
}

variable "custom_endpoint_certificate_arn" {
  description = "ACM certificate ARN for custom endpoint"
  type        = string
  default     = null
}

# ============================================================================
# Auto-Tune Options
# ============================================================================

variable "auto_tune_enabled" {
  description = "Enable Auto-Tune"
  type        = bool
  default     = true
}

variable "auto_tune_rollback_on_disable" {
  description = "Rollback strategy when Auto-Tune is disabled"
  type        = string
  default     = "NO_ROLLBACK"
}

# ============================================================================
# Software Update Options
# ============================================================================

variable "auto_software_update_enabled" {
  description = "Enable automatic software updates"
  type        = bool
  default     = false
}

# ============================================================================
# Off-Peak Window Options
# ============================================================================

variable "off_peak_window_enabled" {
  description = "Enable off-peak window for maintenance"
  type        = bool
  default     = true
}

variable "off_peak_window_start_hour" {
  description = "Start hour for off-peak window (UTC)"
  type        = number
  default     = 0
}

# ============================================================================
# Log Publishing Options
# ============================================================================

variable "create_cloudwatch_log_groups" {
  description = "Create CloudWatch log groups for OpenSearch logs"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Retention period for CloudWatch logs"
  type        = number
  default     = 30
}

variable "log_types" {
  description = "List of log types to publish to CloudWatch"
  type        = list(string)
  default     = ["ES_APPLICATION_LOGS", "INDEX_SLOW_LOGS", "SEARCH_SLOW_LOGS"]
}

# ============================================================================
# Advanced Options
# ============================================================================

variable "advanced_options" {
  description = "Advanced configuration options"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Timeouts
# ============================================================================

variable "create_timeout" {
  description = "Timeout for domain creation"
  type        = string
  default     = "60m"
}

variable "update_timeout" {
  description = "Timeout for domain updates"
  type        = string
  default     = "60m"
}

variable "delete_timeout" {
  description = "Timeout for domain deletion"
  type        = string
  default     = "60m"
}

# ============================================================================
# Service Linked Role
# ============================================================================

variable "create_service_linked_role" {
  description = "Create OpenSearch service-linked role"
  type        = bool
  default     = true
}

# ============================================================================
# Tags
# ============================================================================

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Service   = "OpenSearch"
  }
}
