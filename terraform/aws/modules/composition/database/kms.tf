# =========================================================================
# KMS KEY - For RDS Database Encryption
# =========================================================================

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# KMS Key Policy for RDS Service Access
# This policy allows RDS service to use the KMS key for encryption/decryption
data "aws_iam_policy_document" "rds_kms_policy" {
  count = local.kms_create ? 1 : 0

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow RDS Service"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["rds.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  count = local.kms_create ? 1 : 0

  # Basic Configuration
  create      = true
  description = try(var.kms.description, "KMS key for ${local.name_prefix} database encryption")

  # Key Type Configuration
  multi_region = try(var.kms.multi_region, false)

  # Replica Key Configuration (for creating replicas from a multi-region primary)
  create_replica           = try(var.kms.create_replica, false)
  create_replica_external  = try(var.kms.create_replica_external, false)
  primary_key_arn          = try(var.kms.primary_key_arn, null)
  primary_external_key_arn = try(var.kms.primary_external_key_arn, null)

  # External CMK Configuration
  create_external     = try(var.kms.create_external, false)
  key_material_base64 = try(var.kms.key_material_base64, null)
  valid_to            = try(var.kms.valid_to, null)

  # Key Specifications
  key_usage                = try(var.kms.key_usage, "ENCRYPT_DECRYPT")
  customer_master_key_spec = try(var.kms.customer_master_key_spec, "SYMMETRIC_DEFAULT")
  key_spec                 = try(var.kms.key_spec, null)
  deletion_window_in_days  = try(var.kms.deletion_window_in_days, 30)

  # Key State
  is_enabled                         = try(var.kms.is_enabled, true)
  enable_key_rotation                = try(var.kms.enable_key_rotation, true)
  rotation_period_in_days            = try(var.kms.rotation_period_in_days, null)
  bypass_policy_lockout_safety_check = try(var.kms.bypass_policy_lockout_safety_check, null)

  # Aliases
  aliases                 = try(var.kms.aliases, ["alias/${local.name_prefix}"])
  aliases_use_name_prefix = try(var.kms.aliases_use_name_prefix, false)

  # Access control (for key policy)
  key_administrators = try(var.kms.key_administrators, [])
  key_users          = try(var.kms.key_users, [])
  key_service_users  = try(var.kms.key_service_users, [])
  key_owners         = try(var.kms.key_owners, [])

  # Policy for RDS service access
  source_policy_documents = [data.aws_iam_policy_document.rds_kms_policy[0].json]

  # Tags - handled internally by module
  tags = local.common_tags
}
