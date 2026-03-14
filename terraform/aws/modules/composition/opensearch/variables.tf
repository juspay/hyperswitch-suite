################################################################################
# General Variables
################################################################################

variable "environment" {
  description = "Environment name (dev/sandbox/prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "AWS region. Defaults to the region set in the provider configuration"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Domain Configuration
################################################################################

variable "domain_name" {
  description = "Name of the OpenSearch domain. If not provided, will be generated from environment and project_name"
  type        = string
  default     = null
}

variable "engine_version" {
  description = "Version of the OpenSearch engine. Format: 'OpenSearch_X.Y' or 'Elasticsearch_X.Y'"
  type        = string
  default     = "OpenSearch_2.13"

  validation {
    condition     = can(regex("^(Elasticsearch_[0-9]{1}\\.[0-9]{1,2}|OpenSearch_[0-9]{1,2}\\.[0-9]{1,2})$", var.engine_version))
    error_message = "Engine version must be in format 'OpenSearch_X.Y' or 'Elasticsearch_X.Y' (e.g., OpenSearch_2.13, Elasticsearch_7.10)."
  }
}

variable "ip_address_type" {
  description = "The IP address type for the endpoint. Valid values: ipv4, dualstack"
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "IP address type must be either 'ipv4' or 'dualstack'."
  }
}

################################################################################
# Cluster Configuration
################################################################################

variable "instance_type" {
  description = "Instance type for the OpenSearch data nodes"
  type        = string
  default     = "r6g.large.search"
}

variable "instance_count" {
  description = "Number of data nodes in the cluster"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1
    error_message = "Instance count must be at least 1."
  }
}

variable "dedicated_master_enabled" {
  description = "Whether dedicated master nodes are enabled"
  type        = bool
  default     = false
}

variable "dedicated_master_type" {
  description = "Instance type for dedicated master nodes"
  type        = string
  default     = "c6g.large.search"
}

variable "dedicated_master_count" {
  description = "Number of dedicated master nodes (should be 3 for production)"
  type        = number
  default     = 3
}

variable "zone_awareness_enabled" {
  description = "Whether zone awareness is enabled"
  type        = bool
  default     = false
}

variable "availability_zone_count" {
  description = "Number of availability zones for zone awareness (2 or 3)"
  type        = number
  default     = 2

  validation {
    condition     = contains([2, 3], var.availability_zone_count)
    error_message = "Availability zone count must be 2 or 3."
  }
}

variable "multi_az_with_standby_enabled" {
  description = "Whether Multi-AZ with standby is enabled"
  type        = bool
  default     = false
}

variable "warm_enabled" {
  description = "Whether UltraWarm data nodes are enabled"
  type        = bool
  default     = false
}

variable "warm_type" {
  description = "Instance type for UltraWarm data nodes"
  type        = string
  default     = null
}

variable "warm_count" {
  description = "Number of UltraWarm data nodes"
  type        = number
  default     = null
}

################################################################################
# EBS Storage Configuration
################################################################################

variable "ebs_enabled" {
  description = "Whether EBS volumes are attached to data nodes"
  type        = bool
  default     = true
}

variable "volume_type" {
  description = "Type of EBS volumes (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.volume_type)
    error_message = "Volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "volume_size" {
  description = "Size of EBS volumes in GiB"
  type        = number
  default     = 100

  validation {
    condition     = var.volume_size >= 10 && var.volume_size <= 3072
    error_message = "Volume size must be between 10 and 3072 GiB."
  }
}

variable "volume_iops" {
  description = "Baseline IOPS for EBS volumes (gp3, io1, io2)"
  type        = number
  default     = null
}

variable "volume_throughput" {
  description = "Throughput in MiB/s for gp3 volumes"
  type        = number
  default     = null
}

################################################################################
# VPC Configuration
################################################################################

variable "vpc_id" {
  description = "VPC ID where the OpenSearch domain will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the OpenSearch domain"
  type        = list(string)
}

variable "create_security_group" {
  description = "Whether to create a security group for OpenSearch"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name of the security group (if create_security_group is true)"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description of the security group"
  type        = string
  default     = null
}

variable "existing_security_group_ids" {
  description = "List of existing security group IDs to attach to the OpenSearch domain"
  type        = list(string)
  default     = []
}


################################################################################
# Security Configuration
################################################################################

variable "encrypt_at_rest_enabled" {
  description = "Whether encryption at rest is enabled"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption at rest. If null, uses AWS-managed key"
  type        = string
  default     = null
}

variable "node_to_node_encryption_enabled" {
  description = "Whether node-to-node encryption is enabled"
  type        = bool
  default     = true
}

variable "enforce_https" {
  description = "Whether HTTPS is enforced for the domain endpoint"
  type        = bool
  default     = true
}

variable "tls_security_policy" {
  description = "TLS security policy for the domain endpoint"
  type        = string
  default     = "Policy-Min-TLS-1-2-2019-07"

  validation {
    condition     = contains(["Policy-Min-TLS-1-0-2019-07", "Policy-Min-TLS-1-2-2019-07"], var.tls_security_policy)
    error_message = "TLS security policy must be 'Policy-Min-TLS-1-0-2019-07' or 'Policy-Min-TLS-1-2-2019-07'."
  }
}

################################################################################
# Fine-Grained Access Control
################################################################################

variable "advanced_security_enabled" {
  description = "Whether fine-grained access control is enabled"
  type        = bool
  default     = false
}

variable "internal_user_database_enabled" {
  description = "Whether internal user database is enabled"
  type        = bool
  default     = false
}

variable "master_user_arn" {
  description = "ARN of the master user for fine-grained access control"
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
  description = "Whether anonymous authentication is enabled"
  type        = bool
  default     = false
}

################################################################################
# Custom Endpoint
################################################################################

variable "custom_endpoint_enabled" {
  description = "Whether custom endpoint is enabled"
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

################################################################################
# Auto-Tune Options
################################################################################

variable "auto_tune_enabled" {
  description = "Whether Auto-Tune is enabled"
  type        = bool
  default     = true
}

variable "auto_tune_rollback_on_disable" {
  description = "Rollback strategy when Auto-Tune is disabled"
  type        = string
  default     = "NO_ROLLBACK"

  validation {
    condition     = contains(["NO_ROLLBACK", "DEFAULT_ROLLBACK"], var.auto_tune_rollback_on_disable)
    error_message = "Auto-Tune rollback on disable must be 'NO_ROLLBACK' or 'DEFAULT_ROLLBACK'."
  }
}

################################################################################
# Software Update Options
################################################################################

variable "auto_software_update_enabled" {
  description = "Whether automatic software updates are enabled"
  type        = bool
  default     = false
}

################################################################################
# Off-Peak Window Options
################################################################################

variable "off_peak_window_enabled" {
  description = "Whether off-peak window is enabled for maintenance"
  type        = bool
  default     = true
}

variable "off_peak_window_start_hour" {
  description = "Start hour for off-peak window (0-23 UTC)"
  type        = number
  default     = 0

  validation {
    condition     = var.off_peak_window_start_hour >= 0 && var.off_peak_window_start_hour <= 23
    error_message = "Off-peak window start hour must be between 0 and 23."
  }
}

################################################################################
# Log Publishing Options
################################################################################

variable "create_cloudwatch_log_groups" {
  description = "Whether to create CloudWatch log groups for OpenSearch logs"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain CloudWatch log events"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "CloudWatch log retention must be a valid value (1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, or 3653 days)."
  }
}

variable "log_types" {
  description = "List of log types to publish to CloudWatch (ES_APPLICATION_LOGS, INDEX_SLOW_LOGS, SEARCH_SLOW_LOGS, AUDIT_LOGS)"
  type        = list(string)
  default     = ["ES_APPLICATION_LOGS", "INDEX_SLOW_LOGS", "SEARCH_SLOW_LOGS"]

  validation {
    condition     = alltrue([for log_type in var.log_types : contains(["ES_APPLICATION_LOGS", "INDEX_SLOW_LOGS", "SEARCH_SLOW_LOGS", "AUDIT_LOGS"], log_type)])
    error_message = "Log types must be one of: ES_APPLICATION_LOGS, INDEX_SLOW_LOGS, SEARCH_SLOW_LOGS, AUDIT_LOGS."
  }
}

################################################################################
# Advanced Options
################################################################################

variable "advanced_options" {
  description = "Key-value string pairs to specify advanced configuration options"
  type        = map(string)
  default     = {}
}

################################################################################
# Timeouts
################################################################################

variable "create_timeout" {
  description = "Timeout for creating the OpenSearch domain"
  type        = string
  default     = "60m"
}

variable "update_timeout" {
  description = "Timeout for updating the OpenSearch domain"
  type        = string
  default     = "60m"
}

variable "delete_timeout" {
  description = "Timeout for deleting the OpenSearch domain"
  type        = string
  default     = "60m"
}

################################################################################
# Service Linked Role
################################################################################

variable "create_service_linked_role" {
  description = "Whether to create the OpenSearch service-linked role"
  type        = bool
  default     = true
}
