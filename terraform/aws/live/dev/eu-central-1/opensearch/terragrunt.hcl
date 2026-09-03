include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../..//modules/composition/opensearch"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id           = "vpc-XXXXXXXXXXXXXXXXX"
    utils_subnet_ids = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-YYYYYYYYYYYYYYYYY", "subnet-ZZZZZZZZZZZZZZZZZ"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  domain_name     = "hyperswitch-xxxxx"
  engine_version  = "Elasticsearch_7.10"
  ip_address_type = "ipv4"

  instance_type  = "r7g.large.search"
  instance_count = 1

  dedicated_master_enabled = false
  dedicated_master_type    = "c6g.large.search"
  dedicated_master_count   = 3

  zone_awareness_enabled        = false
  availability_zone_count       = 2
  multi_az_with_standby_enabled = false

  warm_enabled = false
  warm_type    = null
  warm_count   = null

  ebs_enabled       = true
  volume_type       = "gp3"
  volume_size       = 300
  volume_iops       = 3000
  volume_throughput = 250

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = slice(dependency.vpc.outputs.utils_subnet_ids, 0, 1)

  create_security_group       = true
  security_group_name         = "dev-hyperswitch-opensearch-sg"
  security_group_description  = "Security group for Hyperswitch Dev OpenSearch domain"
  existing_security_group_ids = []

  encrypt_at_rest_enabled         = true
  kms_key_id                      = null
  node_to_node_encryption_enabled = true
  enforce_https                   = true
  tls_security_policy             = "Policy-Min-TLS-1-2-2019-07"

  advanced_security_enabled      = false
  internal_user_database_enabled = false
  master_user_arn                = null
  master_user_name               = null
  master_user_password           = null
  anonymous_auth_enabled         = false

  custom_endpoint_enabled         = false
  custom_endpoint                 = null
  custom_endpoint_certificate_arn = null

  auto_tune_enabled             = true
  auto_tune_rollback_on_disable = "NO_ROLLBACK"

  auto_software_update_enabled = false

  off_peak_window_enabled    = true
  off_peak_window_start_hour = 0

  create_cloudwatch_log_groups           = true
  cloudwatch_log_group_retention_in_days = 30
  log_types                              = ["ES_APPLICATION_LOGS", "INDEX_SLOW_LOGS", "SEARCH_SLOW_LOGS"]

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  create_timeout = "60m"
  update_timeout = "60m"
  delete_timeout = "60m"

  create_service_linked_role = true

  tags = {
    Environment = "dev"
    Project     = "hyperswitch"
    Service     = "OpenSearch"
    ManagedBy   = "Terraform"
  }
}
