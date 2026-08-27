# ============================================================================
# CMEK for the locker's disks and its Cloud SQL database
# ============================================================================
module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "4.1.2"

  project_id = var.project_id
  location   = var.region
  keyring    = "${local.name_prefix}-keyring"
  keys       = ["locker"]

  key_protection_level = "SOFTWARE"
  key_rotation_period  = "7776000s" # 90 days

  labels = local.common_labels
}
