locals {
  name_prefix = "${var.environment}-${var.project_name}-sql"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "database"
      "managed_by"  = "terraform"
    },
    var.labels
  )

  instance_name = var.instance_name != null ? var.instance_name : "${local.name_prefix}-pg"

  kms_create = var.kms != null ? var.kms.create : false
  kms_key_name = var.encryption_key_name != null ? var.encryption_key_name : (
    local.kms_create ? module.kms[0].keys[var.kms.key_name] : null
  )

  # Only store in Secret Manager when the password is actually
  # module-generated - an explicit var.master_password means there's nothing
  # for the registry submodule to generate, so generated_user_password would
  # be empty.
  secret_manager_create = var.secret_manager != null ? (var.secret_manager.create && var.master_password == null) : false
  secret_manager_secret_id = local.secret_manager_create ? coalesce(
    var.secret_manager.secret_id, "${local.instance_name}-master-password"
  ) : null
}
