# ============================================================================
# OpenSearch Domain Configuration - Dev Environment
# ============================================================================
# This file contains the actual values for the OpenSearch domain deployment.
# Copy this file to terraform.tfvars and update the values as needed.
# ============================================================================

# ============================================================================
# Environment Configuration
# ============================================================================

environment  = "dev"
project_name = "hyperswitch"
region       = "eu-central-1"

# ============================================================================
# Domain Configuration
# ============================================================================

# Domain name - must be unique within the AWS account
domain_name     = "hyperswitch-xxxxx"
engine_version  = "Elasticsearch_7.10"
ip_address_type = "ipv4"

# ============================================================================
# Cluster Configuration
# ============================================================================

# Instance type for data nodes
# Options: r6g.large.search, r6g.xlarge.search, r7g.large.search, etc.
instance_type = "r7g.large.search"

# Number of data nodes (1-80, depending on instance type)
instance_count = 1

# Dedicated master nodes (recommended for production with 3+ data nodes)
dedicated_master_enabled = false
dedicated_master_type    = "c6g.large.search"
dedicated_master_count   = 3

# Zone awareness for high availability across AZs
zone_awareness_enabled  = false
availability_zone_count = 2

# Multi-AZ with standby for mission-critical workloads
multi_az_with_standby_enabled = false

# UltraWarm nodes for warm data storage
warm_enabled = false
warm_type    = null
warm_count   = null

# ============================================================================
# EBS Storage Configuration
# ============================================================================

ebs_enabled       = true
volume_type       = "gp3"
volume_size       = 300  # GiB
volume_iops       = 3000 # IOPS for gp3
volume_throughput = 250  # MiB/s for gp3

# ============================================================================
# VPC Configuration
# ============================================================================

# VPC ID - update with your VPC ID
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

# Subnet IDs - update with your subnet IDs (use utils subnets for OpenSearch)
subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx"]

# Security Group Configuration
create_security_group      = true
security_group_name        = "dev-hyperswitch-opensearch-sg"
security_group_description = "Security group for Hyperswitch Dev OpenSearch domain"

# Existing security groups to attach (from the AWS console)
existing_security_group_ids = [
  "sg-xxxxxxxxxxxxxxxxx", 
  "sg-xxxxxxxxxxxxxxxxx"  
]


# ============================================================================
# Security Configuration
# ============================================================================

encrypt_at_rest_enabled         = true
kms_key_id                      = null # Uses AWS-managed key
node_to_node_encryption_enabled = true
enforce_https                   = true
tls_security_policy             = "Policy-Min-TLS-1-2-2019-07"

# ============================================================================
# Fine-Grained Access Control (FGAC)
# ============================================================================

# Enable FGAC for user/role-based access control
advanced_security_enabled      = false
internal_user_database_enabled = false
master_user_arn                = null
master_user_name               = null
master_user_password           = null
anonymous_auth_enabled         = false

# ============================================================================
# Custom Endpoint (Optional)
# ============================================================================

custom_endpoint_enabled         = false
custom_endpoint                 = null
custom_endpoint_certificate_arn = null

# ============================================================================
# Auto-Tune Options
# ============================================================================

auto_tune_enabled             = true
auto_tune_rollback_on_disable = "NO_ROLLBACK"

# ============================================================================
# Software Update Options
# ============================================================================

# Set to true for production to get latest security patches
auto_software_update_enabled = false

# ============================================================================
# Off-Peak Window Options
# ============================================================================

off_peak_window_enabled    = true
off_peak_window_start_hour = 0 # UTC

# ============================================================================
# Log Publishing Options
# ============================================================================

create_cloudwatch_log_groups           = true
cloudwatch_log_group_retention_in_days = 30
log_types                              = ["ES_APPLICATION_LOGS", "INDEX_SLOW_LOGS", "SEARCH_SLOW_LOGS"]

# ============================================================================
# Advanced Options
# ============================================================================

advanced_options = {
  "rest.action.multi.allow_explicit_index" = "true"
}

# ============================================================================
# Timeouts
# ============================================================================

create_timeout = "60m"
update_timeout = "60m"
delete_timeout = "60m"

# ============================================================================
# Service Linked Role
# ============================================================================

create_service_linked_role = true


# ============================================================================
# Tags
# ============================================================================

tags = {
  Environment = "dev"
  Project     = "hyperswitch"
  Service     = "OpenSearch"
  ManagedBy   = "Terraform"
}
