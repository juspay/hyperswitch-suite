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

  # A secondary cluster is defined purely by pointing at a primary; upstream
  # derives cluster_type from the same signal.
  is_secondary = var.primary_cluster_name != null

  primary_instance_id = coalesce(var.primary_instance.instance_id, "${local.cluster_id}-primary")

  # Read pools, normalised so the map key doubles as the default instance_id -
  # this is what lets the live layer address a pool by name the way the AWS
  # module's cluster_instances map does.
  read_pool_instances = {
    for k, r in var.read_pool_instances : k => merge(r, {
      instance_id = coalesce(r.instance_id, k)
    })
  }

  # Upstream iterates read pools with for_each keyed on instance_id, so its
  # read_instance_ids / read_instance_ips lists come back sorted by that key.
  # Sorting the same way lets outputs.tf zip them back into a keyed map.
  read_pool_ids_sorted = sort([for r in local.read_pool_instances : r.instance_id])

  # Upstream applies primary_instance.labels to the read pool instances too,
  # so this is the label set for every instance in the cluster.
  instance_labels = merge(local.common_labels, var.primary_instance.labels)

  kms_create = var.kms != null ? var.kms.create : false
  kms_key_name = var.encryption_key_name != null ? var.encryption_key_name : (
    local.kms_create ? module.kms[0].keys[var.kms.key_name] : null
  )

  # AlloyDB has no built-in "generate a password for me" path (unlike Cloud
  # SQL's random_password.user-password[0] inside the sql-db registry
  # module) - generate it ourselves when master_password is left unset.
  # A secondary cluster inherits the primary's users - it has no initial user
  # of its own, so there is nothing to generate or store.
  generate_password = var.master_password == null && !local.is_secondary
  master_password   = local.generate_password ? random_password.master[0].result : var.master_password

  secret_manager_create = var.secret_manager != null ? (var.secret_manager.create && local.generate_password) : false
  secret_manager_secret_id = local.secret_manager_create ? coalesce(
    var.secret_manager.secret_id, "${local.cluster_id}-master-password"
  ) : null
}
