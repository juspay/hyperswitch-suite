locals {
  name_prefix = "${var.environment}-${var.project_name}-locker"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "locker"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  locker_security_group_id = aws_security_group.locker.id
  locker_subnet_ids        = var.locker_subnet_ids

  # Key pair logic:
  # - If create_key_pair is true, use the created key pair
  # - Otherwise, use the provided key_name
  key_name = var.create_key_pair ? aws_key_pair.locker[0].key_name : var.key_name

  # Auto-generate key pair name if not provided
  key_pair_name = var.key_name != null ? var.key_name : "${local.name_prefix}-key"

  # KMS logic - concat created key ARN with additional key ARNs
  kms_create   = var.kms != null ? var.kms.create : false
  kms_key_arns = concat(
    local.kms_create ? [module.kms[0].key_arn] : [],
    try(var.kms.key_arns, [])
  )
}
