# CMEK key for the vault's AlloyDB cluster. Created here rather than via
# ../alloydb's own `kms` input so it outlives a rebuild of the cluster: a
# destroyed key takes every backup encrypted under it, and those backups are
# the vault's only recovery path.
module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "4.1.2"

  count = var.create_kms_key && var.encryption_key_name == null ? 1 : 0

  project_id = var.project_id
  location   = var.region
  keyring    = coalesce(var.kms_keyring_name, "${local.name_prefix}-keyring")
  keys       = [var.kms_key_id]

  key_protection_level = var.kms_protection_level
  key_rotation_period  = var.kms_rotation_period

  # Removing the key from state while the cluster still references it leaves
  # the cluster unreadable, so keep it even when this module is torn down.
  prevent_destroy = var.kms_prevent_destroy

  labels = local.common_labels
}
