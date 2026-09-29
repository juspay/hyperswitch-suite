module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  count = var.kms.create ? 1 : 0

  create                             = true
  description                        = coalesce(var.kms.description, "KMS key for ${local.name_prefix}")
  multi_region                       = var.kms.multi_region
  deletion_window_in_days            = var.kms.deletion_window_in_days
  enable_key_rotation                = var.kms.enable_key_rotation
  rotation_period_in_days            = var.kms.rotation_period_in_days
  bypass_policy_lockout_safety_check = var.kms.bypass_policy_lockout_safety_check

  aliases                 = length(var.kms.aliases) > 0 ? var.kms.aliases : ["alias/${local.name_prefix}"]
  aliases_use_name_prefix = var.kms.aliases_use_name_prefix

  key_administrators = var.kms.key_administrators
  key_users          = var.kms.key_users
  key_service_users  = var.kms.key_service_users
  key_owners         = var.kms.key_owners

  source_policy_documents = var.kms.source_policy_documents

  tags = local.common_tags
}
