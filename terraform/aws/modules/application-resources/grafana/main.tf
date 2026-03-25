# =========================================================================
# IAM - ROLE
# =========================================================================
resource "aws_iam_role" "this" {
  name                  = var.role_name != null ? var.role_name : "${local.name_prefix}-role"
  description           = var.role_description != null ? var.role_description : "IAM role for ${title(var.app_name)} ${title(var.environment)} application"
  path                  = var.role_path
  max_session_duration  = var.max_session_duration
  force_detach_policies = var.force_detach_policies

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # OIDC trust relationships for EKS IRSA
      [
        for cluster_name, statement in local.cluster_oidc_statements : {
          Effect = "Allow"
          Principal = {
            Federated = statement.oidc_arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${statement.oidc_url}:aud" = "sts.amazonaws.com"
              "${statement.oidc_url}:sub" = statement.subjects
            }
          }
        }
      ],
      # Additional AWS principal trust relationships
      local.assume_role_principals_enabled ? [
        {
          Effect = "Allow"
          Principal = {
            AWS = var.assume_role_principals
          }
          Action = "sts:AssumeRole"
        }
      ] : [],
      # Additional custom trust statements
      var.additional_assume_role_statements
    )
  })

  tags = local.common_tags
}

# =========================================================================
# IAM - AWS MANAGED POLICY ATTACHMENTS
# =========================================================================
resource "aws_iam_role_policy_attachment" "aws_managed" {
  for_each = local.aws_managed_policies_enabled ? toset(var.aws_managed_policy_names) : toset([])

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

# =========================================================================
# IAM - CUSTOMER MANAGED POLICY ATTACHMENTS
# =========================================================================
resource "aws_iam_role_policy_attachment" "customer_managed" {
  for_each = local.customer_managed_policies_enabled ? toset(var.customer_managed_policy_arns) : toset([])

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# =========================================================================
# DATABASE
# =========================================================================
module "database" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/database?ref=database-v0.1.4"

  count = var.create_database ? 1 : 0

  environment  = var.environment
  project_name = var.project_name
  region       = var.region
  tags         = local.common_tags

  # Network Configuration
  vpc_id                 = var.database_vpc_id
  subnet_ids             = var.database_subnet_ids
  db_subnet_group_name   = var.database_db_subnet_group_name
  create_db_subnet_group = var.database_create_db_subnet_group
  network_type           = var.database_network_type
  port                   = var.database_port
  availability_zones     = var.database_availability_zones

  # Cluster Configuration
  cluster_identifier        = var.database_cluster_identifier
  engine                    = var.database_engine
  engine_version            = var.database_engine_version
  engine_mode               = var.database_engine_mode
  engine_lifecycle_support  = var.database_engine_lifecycle_support
  db_cluster_instance_class = var.database_db_cluster_instance_class
  allocated_storage         = var.database_allocated_storage
  storage_type              = var.database_storage_type
  iops                      = var.database_iops

  # Database Configuration
  database_name                 = var.database_name
  master_username               = var.database_master_username
  master_password               = var.database_master_password
  manage_master_user_password   = var.database_manage_master_user_password
  master_user_secret_kms_key_id = var.database_master_user_secret_kms_key_id

  # Instance Configuration
  cluster_instances = var.database_cluster_instances

  # Serverless Configuration
  serverlessv2_scaling_configuration = var.database_serverlessv2_scaling_configuration
  scaling_configuration              = var.database_scaling_configuration

  # Parameter Groups
  db_cluster_parameter_group_name    = var.database_db_cluster_parameter_group_name
  db_instance_parameter_group_name   = var.database_db_instance_parameter_group_name
  create_custom_parameter_group      = var.database_create_custom_parameter_group
  custom_parameter_group_name        = var.database_custom_parameter_group_name
  custom_parameter_group_family      = var.database_custom_parameter_group_family
  custom_parameter_group_description = var.database_custom_parameter_group_description
  custom_parameter_group_parameters  = var.database_custom_parameter_group_parameters

  # Backup Configuration
  backup_retention_period      = var.database_backup_retention_period
  preferred_backup_window      = var.database_preferred_backup_window
  preferred_maintenance_window = var.database_preferred_maintenance_window
  skip_final_snapshot          = var.database_skip_final_snapshot
  final_snapshot_identifier    = var.database_final_snapshot_identifier
  copy_tags_to_snapshot        = var.database_copy_tags_to_snapshot
  snapshot_identifier          = var.database_snapshot_identifier

  # Security
  deletion_protection       = var.database_deletion_protection
  storage_encrypted         = var.database_storage_encrypted
  kms_key_id                = var.database_kms_key_id
  delete_automated_backups  = var.database_delete_automated_backups
  ca_certificate_identifier = var.database_ca_certificate_identifier

  # Network Security
  vpc_security_group_ids     = var.database_vpc_security_group_ids
  create_security_group      = var.database_create_security_group
  security_group_name        = var.database_security_group_name
  security_group_description = var.database_security_group_description

  # Monitoring
  enabled_cloudwatch_logs_exports       = var.database_enabled_cloudwatch_logs_exports
  performance_insights_enabled          = var.database_performance_insights_enabled
  performance_insights_kms_key_id       = var.database_performance_insights_kms_key_id
  performance_insights_retention_period = var.database_performance_insights_retention_period
  monitoring_interval                   = var.database_monitoring_interval
  monitoring_role_arn                   = var.database_monitoring_role_arn
  database_insights_mode                = var.database_database_insights_mode

  # IAM
  iam_database_authentication_enabled = var.database_iam_database_authentication_enabled
  iam_roles                           = var.database_iam_roles

  # Version Management
  apply_immediately           = var.database_apply_immediately
  allow_major_version_upgrade = var.database_allow_major_version_upgrade

  # Features
  enable_http_endpoint = var.database_enable_http_endpoint
  backtrack_window     = var.database_backtrack_window

  # Global Cluster
  create_global_cluster          = var.database_create_global_cluster
  global_cluster_identifier      = var.database_global_cluster_identifier
  global_deletion_protection     = var.database_global_deletion_protection
  enable_global_write_forwarding = var.database_enable_global_write_forwarding
  use_existing_as_global_primary = var.database_use_existing_as_global_primary
  source_db_cluster_identifier   = var.database_source_db_cluster_identifier
}
