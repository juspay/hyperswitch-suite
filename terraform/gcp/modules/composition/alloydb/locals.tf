locals {
  name_prefix = "${var.environment}-${var.project_name}"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "database"
      "managed_by"  = "terraform"
    },
    var.labels
  )

  cluster_id = var.cluster_id != null ? var.cluster_id : "${local.name_prefix}-alloydb"

  kms_create = var.kms != null ? var.kms.create : false
  kms_key_name = var.encryption_key_name != null ? var.encryption_key_name : (
    local.kms_create ? module.kms[0].keys[var.kms.key_name] : null
  )

  # AlloyDB has no built-in "generate a password for me" path (unlike Cloud
  # SQL's random_password.user-password[0] inside the sql-db registry
  # module) - generate it ourselves when master_password is left unset.
  generate_password = var.master_password == null
  master_password   = local.generate_password ? random_password.master[0].result : var.master_password

  secret_manager_create = var.secret_manager != null ? (var.secret_manager.create && local.generate_password) : false
  secret_manager_secret_id = local.secret_manager_create ? coalesce(
    var.secret_manager.secret_id, "${local.cluster_id}-master-password"
  ) : null
}
