include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc_network" {
  config_path = try(values.vpc_config_path, "../../vpc-network")

  mock_outputs = {
    vpc_id                         = "vpc-12345678"
    data_stack_subnet_ids          = ["subnet-12345678", "subnet-12345679"]
    vpc_endpoint_security_group_id = "sg-12345678"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/opensearch?ref=opensearch-v0.1.0"
}

inputs = {
  # ============================================================================
  # Environment Configuration
  # ============================================================================
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  # ============================================================================
  # Domain Configuration
  # ============================================================================
  domain_name     = try(values.domain_name, "${include.root.locals.project_name}-${include.root.locals.environment.full}-${include.root.locals.region_code}")
  engine_version  = try(values.engine_version, "Elasticsearch_7.10")
  ip_address_type = "ipv4"

  # ============================================================================
  # Cluster Configuration
  # ============================================================================
  instance_type  = try(values.instance_type, "r7g.large.search")
  instance_count = try(values.instance_count, 1)

  # Dedicated master nodes (disabled for single-node setups)
  dedicated_master_enabled = try(values.dedicated_master_enabled, false)
  dedicated_master_type    = "c6g.large.search"
  dedicated_master_count   = 3

  # Zone awareness (disabled for single-AZ deployment)
  zone_awareness_enabled        = try(values.zone_awareness_enabled, false)
  availability_zone_count       = 2
  multi_az_with_standby_enabled = false

  # UltraWarm nodes
  warm_enabled = false
  warm_type    = null
  warm_count   = null

  # ============================================================================
  # EBS Storage Configuration
  # ============================================================================
  ebs_enabled       = true
  volume_type       = "gp3"
  volume_size       = try(values.volume_size, 300) # GiB
  volume_iops       = 3000
  volume_throughput = 250 # MiB/s

  # ============================================================================
  # VPC Configuration - Single subnet for single-AZ deployment
  # ============================================================================
  vpc_id     = dependency.vpc_network.outputs.vpc_id
  subnet_ids = [dependency.vpc_network.outputs.data_stack_subnet_ids[0]]

  # Security Group Configuration
  create_security_group      = true
  security_group_name        = "opensearch-sg-${include.root.locals.environment.short}-${include.root.locals.region_code}"
  security_group_description = "Security group for ${include.root.locals.project_name} ${include.root.locals.environment.full} OpenSearch domain"

  existing_security_group_ids = [
    dependency.vpc_network.outputs.vpc_endpoint_security_group_id
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
  # The OpenSearch service-linked role is account-wide and already created by
  # the primary-region opensearch unit, so passive regions must not create it again.
  create_service_linked_role = !try(values.is_passive, false)

  # ============================================================================
  # Tags
  # ============================================================================
  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
    Service     = "OpenSearch"
  }
}
