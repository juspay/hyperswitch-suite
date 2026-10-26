# KMS (CMEK for Hyperswitch application-level encryption)
module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "4.1.2"

  count = local.kms_enabled ? 1 : 0

  project_id = var.project_id
  location   = coalesce(var.kms.location, "global")
  keyring    = coalesce(var.kms.keyring_name, "${local.name_prefix}-keyring")
  keys       = [coalesce(var.kms.key_name, "hyperswitch")]

  key_protection_level = "SOFTWARE"
  key_rotation_period  = coalesce(var.kms.rotation_period, "7776000s") # 90 days

  labels = local.common_labels
}

resource "google_kms_crypto_key_iam_member" "hyperswitch" {
  count = local.kms_enabled ? 1 : 0

  crypto_key_id = module.kms[0].keys[coalesce(var.kms.key_name, "hyperswitch")]
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}
