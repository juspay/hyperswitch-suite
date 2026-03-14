data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_subnet" "this" {
  count = length(var.subnet_ids) > 0 ? 1 : 0
  id    = var.subnet_ids[0]
}

# Fetch default AWS ES KMS key when no custom key is provided
data "aws_kms_key" "default_es" {
  count = var.encrypt_at_rest_enabled && var.kms_key_id == null ? 1 : 0
  key_id = "alias/aws/es"
}

################################################################################
# Service Linked Role
################################################################################

resource "aws_iam_service_linked_role" "opensearch" {
  count = var.create_service_linked_role ? 1 : 0

  aws_service_name = "opensearchservice.amazonaws.com"
  description      = "Service linked role for Amazon OpenSearch Service - ${local.domain_name}"
}

################################################################################
# Security Group (if creating)
################################################################################

resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = local.security_group_name
  description = coalesce(var.security_group_description, "Security group for ${var.project_name} ${var.environment} OpenSearch")
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = local.security_group_name
  })

  lifecycle {
    create_before_destroy = true
  }
}


################################################################################
# OpenSearch Domain (using terraform-aws-modules)
################################################################################

module "opensearch" {
  source  = "terraform-aws-modules/opensearch/aws"
  version = "~> 2.5"

  create = true

  # Domain Configuration
  domain_name    = local.domain_name
  engine_version = var.engine_version
  tags           = local.common_tags

  # IP Address Type
  ip_address_type = var.ip_address_type

  # Cluster Configuration
  cluster_config = {
    instance_type                 = var.instance_type
    instance_count                = var.instance_count
    dedicated_master_enabled      = var.dedicated_master_enabled
    dedicated_master_type         = var.dedicated_master_enabled ? var.dedicated_master_type : null
    dedicated_master_count        = var.dedicated_master_enabled ? var.dedicated_master_count : null
    zone_awareness_enabled        = var.zone_awareness_enabled
    multi_az_with_standby_enabled = var.multi_az_with_standby_enabled
    warm_enabled                  = var.warm_enabled
    warm_type                     = var.warm_enabled ? var.warm_type : null
    warm_count                    = var.warm_enabled ? var.warm_count : null

    zone_awareness_config = var.zone_awareness_enabled ? {
      availability_zone_count = var.availability_zone_count
    } : null
  }

  # EBS Configuration
  ebs_options = {
    ebs_enabled = var.ebs_enabled
    volume_type = var.volume_type
    volume_size = var.volume_size
    iops        = var.volume_iops
    throughput  = var.volume_throughput
  }

  # VPC Configuration
  vpc_options = {
    subnet_ids         = var.subnet_ids
    security_group_ids = concat(var.existing_security_group_ids, var.create_security_group ? [aws_security_group.this[0].id] : [])
  }

  # Encryption at Rest
  encrypt_at_rest = {
    enabled    = var.encrypt_at_rest_enabled
    kms_key_id = var.kms_key_id != null ? var.kms_key_id : (var.encrypt_at_rest_enabled ? data.aws_kms_key.default_es[0].arn : null)
  }

  # Node-to-Node Encryption
  node_to_node_encryption = {
    enabled = var.node_to_node_encryption_enabled
  }

  # Domain Endpoint Options
  domain_endpoint_options = {
    enforce_https                   = var.enforce_https
    tls_security_policy             = var.tls_security_policy
    custom_endpoint_enabled         = var.custom_endpoint_enabled
    custom_endpoint                 = var.custom_endpoint_enabled ? var.custom_endpoint : null
    custom_endpoint_certificate_arn = var.custom_endpoint_enabled ? var.custom_endpoint_certificate_arn : null
  }

  # Advanced Security Options (Fine-Grained Access Control)
  advanced_security_options = {
    enabled                        = var.advanced_security_enabled
    anonymous_auth_enabled         = var.advanced_security_enabled ? var.anonymous_auth_enabled : null
    internal_user_database_enabled = var.advanced_security_enabled ? var.internal_user_database_enabled : null
    master_user_options = var.advanced_security_enabled && (var.master_user_arn != null || var.master_user_name != null) ? {
      master_user_arn      = var.master_user_arn
      master_user_name     = var.master_user_name
      master_user_password = var.master_user_password
    } : null
  }

  # Auto-Tune Options
  auto_tune_options = {
    desired_state       = var.auto_tune_enabled ? "ENABLED" : "DISABLED"
    rollback_on_disable = var.auto_tune_rollback_on_disable
  }

  # Software Update Options
  software_update_options = {
    auto_software_update_enabled = var.auto_software_update_enabled
  }

  # Off-Peak Window Options
  off_peak_window_options = {
    enabled = var.off_peak_window_enabled
    off_peak_window = var.off_peak_window_enabled ? {
      hours = var.off_peak_window_start_hour
    } : null
  }

  # Log Publishing Options
  create_cloudwatch_log_groups           = var.create_cloudwatch_log_groups
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  log_publishing_options = [for log_type in var.log_types : {
    log_type = log_type
    enabled  = true
  }]

  # Security Group (we create our own above)
  create_security_group = false

  # Access Policy - open access within VPC
  enable_access_policy = true
  create_access_policy = true
  access_policy_statements = {
    AllowVPCAccess = {
      sid    = "AllowVPCAccess"
      effect = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      actions   = ["es:*"]
      resources = ["*"]
    }
  }

  # Advanced Options
  advanced_options = merge({
    "rest.action.multi.allow_explicit_index" = "true"
  }, var.advanced_options)

  # Timeouts
  timeouts = {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }

  depends_on = [
    aws_iam_service_linked_role.opensearch
  ]
}
