locals {
  kms_create = var.kms.create
  kms_key_arn = var.kms_key_id != null ? var.kms_key_id : (
    local.kms_create ? module.kms[0].key_arn : var.kms.existing_key_arn
  )
}

# Use the same KMS module version as the database composition module.
# The default key policy delegates permissions to this account's IAM policies.
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"
  count   = local.kms_create ? 1 : 0

  description             = coalesce(var.kms.description, "KMS key for ${local.name_prefix} encryption")
  multi_region            = var.kms.multi_region
  create_replica          = var.kms.create_replica
  primary_key_arn         = var.kms.primary_key_arn
  deletion_window_in_days = var.kms.deletion_window_in_days
  enable_key_rotation     = var.kms.enable_key_rotation
  aliases                 = var.kms.aliases
  key_administrators      = var.kms.key_administrators
  key_users               = var.kms.key_users
  key_service_users       = var.kms.key_service_users
  key_owners              = var.kms.key_owners
  tags                    = local.common_tags
}
