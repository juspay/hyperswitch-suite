# ============================================================================
# Optional CMEK key for Cloud SQL disk encryption
# ============================================================================
module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "4.1.2"

  count = local.kms_create ? 1 : 0

  project_id = var.project_id
  location   = var.region
  keyring    = coalesce(var.kms.keyring_name, "${local.name_prefix}-keyring")
  keys       = [var.kms.key_name]

  key_protection_level = "SOFTWARE"
  key_rotation_period  = coalesce(var.kms.rotation_period, "7776000s") # 90 days

  labels = local.common_labels
}
