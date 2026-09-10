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

  instance_id = var.instance_id != null ? var.instance_id : "${local.name_prefix}-spanner"

  instance_display_name = coalesce(var.instance_display_name, local.instance_id)

  # A Spanner instance config is a topology name, not a region - 'regional-X'
  # is simply the single-region member of that namespace.
  instance_config = coalesce(var.instance_config, "regional-${var.region}")

  # Exactly one of the three is non-null; variables.tf enforces that. Passing
  # the other two as null leaves them unset rather than zeroed.
  autoscaling = var.instance_size.autoscaling

  kms_create = var.kms != null ? var.kms.create : false
  kms_key_name = var.encryption_key_name != null ? var.encryption_key_name : (
    local.kms_create ? module.kms[0].keys[var.kms.key_name] : null
  )

  # Databases, normalised so main.tf reads flat. Per-database kms_key_name wins
  # over the module-level key; deletion_protection falls back to the module
  # default rather than the provider's.
  databases = {
    for k, d in var.databases : k => merge(d, {
      deletion_protection = d.deletion_protection != null ? d.deletion_protection : var.deletion_protection
      kms_key_name        = d.kms_key_name != null ? d.kms_key_name : local.kms_key_name
    })
  }

  # Whether ANY database ends up CMEK-encrypted decides whether the service
  # agent needs a key grant at all.
  any_cmek = length([for k, d in local.databases : k if d.kms_key_name != null]) > 0

  # Backup schedules, keyed by the database they belong to. A schedule is owned
  # by its database and is deleted with it - the backups it already took are
  # not.
  backup_schedules = {
    for k, d in var.databases : k => merge(d.backup_schedule, {
      name = coalesce(d.backup_schedule.name, "${k}-backup")
    })
    if d.backup_schedule != null
  }
}
