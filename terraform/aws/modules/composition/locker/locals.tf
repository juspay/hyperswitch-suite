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

  # Determine which resources to use (created or provided)
  locker_security_group_id = var.create ? try(aws_security_group.locker[0].id, "") : ""
  locker_subnet_id         = var.locker_subnet_id != null ? var.locker_subnet_id : try(aws_subnet.locker[0].id, "")

  # Key pair logic:
  # - If create_key_pair is true, use the created key pair
  # - Otherwise, use the provided key_name
  key_name = var.create && var.create_key_pair ? try(aws_key_pair.locker[0].key_name, var.key_name) : var.key_name

  # Auto-generate key pair name if not provided
  key_pair_name = var.key_name != null ? var.key_name : "${local.name_prefix}-key"

}
