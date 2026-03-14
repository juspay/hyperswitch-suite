# ============================================================================
# OpenSearch Domain Deployment - Dev Environment
# ============================================================================
# This configuration deploys AWS OpenSearch Service Domain:
#   - OpenSearch/Elasticsearch domain for logging and analytics
#   - VPC-enabled endpoint for secure access
#   - EBS storage with configurable size and performance
#   - Encryption at rest and in transit
#   - CloudWatch log publishing
#   - Auto-tune for performance optimization
#
# Access Method: Via VPC internal network only
# Security: Network isolation with security group rules
# High Availability: Optional zone awareness and dedicated masters
# Backups: Hourly automated snapshots
# ============================================================================

# ============================================================================
# OpenSearch Domain Module
# ============================================================================

module "opensearch" {
  source = "../../../../modules/composition/opensearch"

  # Environment Configuration
  environment  = var.environment
  project_name = var.project_name
  region       = var.region
  tags         = var.tags

  # Domain Configuration
  domain_name     = var.domain_name
  engine_version  = var.engine_version
  ip_address_type = var.ip_address_type

  # Cluster Configuration
  instance_type                 = var.instance_type
  instance_count                = var.instance_count
  dedicated_master_enabled      = var.dedicated_master_enabled
  dedicated_master_type         = var.dedicated_master_type
  dedicated_master_count        = var.dedicated_master_count
  zone_awareness_enabled        = var.zone_awareness_enabled
  availability_zone_count       = var.availability_zone_count
  multi_az_with_standby_enabled = var.multi_az_with_standby_enabled
  warm_enabled                  = var.warm_enabled
  warm_type                     = var.warm_type
  warm_count                    = var.warm_count

  # EBS Storage Configuration
  ebs_enabled       = var.ebs_enabled
  volume_type       = var.volume_type
  volume_size       = var.volume_size
  volume_iops       = var.volume_iops
  volume_throughput = var.volume_throughput

  # VPC Configuration
  vpc_id                      = var.vpc_id
  subnet_ids                  = var.subnet_ids
  create_security_group       = var.create_security_group
  security_group_name         = var.security_group_name
  security_group_description  = var.security_group_description
  existing_security_group_ids = var.existing_security_group_ids

  # Security Configuration
  encrypt_at_rest_enabled         = var.encrypt_at_rest_enabled
  kms_key_id                      = var.kms_key_id
  node_to_node_encryption_enabled = var.node_to_node_encryption_enabled
  enforce_https                   = var.enforce_https
  tls_security_policy             = var.tls_security_policy

  # Fine-Grained Access Control
  advanced_security_enabled      = var.advanced_security_enabled
  internal_user_database_enabled = var.internal_user_database_enabled
  master_user_arn                = var.master_user_arn
  master_user_name               = var.master_user_name
  master_user_password           = var.master_user_password
  anonymous_auth_enabled         = var.anonymous_auth_enabled

  # Custom Endpoint
  custom_endpoint_enabled         = var.custom_endpoint_enabled
  custom_endpoint                 = var.custom_endpoint
  custom_endpoint_certificate_arn = var.custom_endpoint_certificate_arn

  # Auto-Tune Options
  auto_tune_enabled             = var.auto_tune_enabled
  auto_tune_rollback_on_disable = var.auto_tune_rollback_on_disable

  # Software Update Options
  auto_software_update_enabled = var.auto_software_update_enabled

  # Off-Peak Window Options
  off_peak_window_enabled    = var.off_peak_window_enabled
  off_peak_window_start_hour = var.off_peak_window_start_hour

  # Log Publishing Options
  create_cloudwatch_log_groups           = var.create_cloudwatch_log_groups
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  log_types                              = var.log_types

  # Advanced Options
  advanced_options = var.advanced_options

  # Timeouts
  create_timeout = var.create_timeout
  update_timeout = var.update_timeout
  delete_timeout = var.delete_timeout

  # Service Linked Role
  create_service_linked_role = var.create_service_linked_role
}

# ============================================================================
# Outputs for K8s Deployments
# ============================================================================

output "opensearch_endpoint" {
  description = "OpenSearch domain endpoint for K8s deployments (use in ELASTICSEARCH_HOSTS env var)"
  value       = "https://${module.opensearch.domain_endpoint}"
}

output "kibana_url" {
  description = "Kibana/Dashboards URL for the domain"
  value       = module.opensearch.kibana_url
}

output "security_group_id" {
  description = "Security group ID for use in security-rules module"
  value       = module.opensearch.security_group_id
}
