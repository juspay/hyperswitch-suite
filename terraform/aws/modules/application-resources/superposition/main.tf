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
# IAM - INLINE POLICIES
# =========================================================================
resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.name
  policy = each.value
}

# =========================================================================
# DATABASE
# =========================================================================
module "database" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/database?ref=database-v0.1.4"

  count = var.create_database ? 1 : 0

  environment = var.environment
  project_name = var.project_name
  region      = var.region
  tags        = local.common_tags

  # Network Configuration
  vpc_id     = var.database_vpc_id
  subnet_ids = var.database_subnet_ids

  # Cluster Configuration
  cluster_identifier = var.database_cluster_identifier
  engine             = var.database_engine
  engine_version     = var.database_engine_version
  engine_mode        = var.database_engine_mode

  # Database Configuration
  database_name                 = var.database_name
  master_username               = var.database_master_username
  master_password               = var.database_master_password
  manage_master_user_password   = var.database_manage_master_user_password

  # Instance Configuration
  cluster_instances = var.database_cluster_instances

  # Serverless v2 Scaling
  serverlessv2_scaling_configuration = var.database_serverlessv2_scaling_configuration

  # Backup Configuration
  backup_retention_period      = var.database_backup_retention_period
  preferred_backup_window      = var.database_preferred_backup_window
  preferred_maintenance_window = var.database_preferred_maintenance_window
  skip_final_snapshot          = var.database_skip_final_snapshot
  final_snapshot_identifier    = var.database_final_snapshot_identifier

  # Security
  deletion_protection = var.database_deletion_protection
  storage_encrypted   = var.database_storage_encrypted
  kms_key_id          = var.database_kms_key_id

  # Network Security
  vpc_security_group_ids  = var.database_vpc_security_group_ids
  create_security_group   = var.database_create_security_group

  # Monitoring
  enabled_cloudwatch_logs_exports       = var.database_enabled_cloudwatch_logs_exports
  performance_insights_enabled          = var.database_performance_insights_enabled
  performance_insights_kms_key_id       = var.database_performance_insights_kms_key_id
  performance_insights_retention_period = var.database_performance_insights_retention_period

  # IAM Authentication
  iam_database_authentication_enabled = var.database_iam_database_authentication_enabled

  # Custom Parameter Group
  create_custom_parameter_group     = var.database_create_custom_parameter_group
  custom_parameter_group_family     = var.database_custom_parameter_group_family
  custom_parameter_group_parameters = var.database_custom_parameter_group_parameters
}
