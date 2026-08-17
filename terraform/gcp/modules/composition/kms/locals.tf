locals {
  name_prefix = "${var.project_name}-${var.environment}"

  keyring_name = coalesce(var.keyring_name, "${local.name_prefix}-keyring")

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "kms"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
