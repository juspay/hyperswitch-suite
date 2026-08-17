# ==============================================================================
# Cloud KMS — Standalone Keyring + Keys
# ==============================================================================
# Creates one KMS keyring per environment and an arbitrary set of CryptoKeys
# within it. Each key can carry its own IAM bindings (e.g. granting Cloud SQL
# or GKE service-agent accounts encrypter/decrypter rights).
#
# The key self-links output by this module can be passed directly into:
#   - composition/cloud-sql  →  var.encryption_key_name
#   - composition/gke        →  var.kms_key_name
#   - composition/gcs-backend →  var.kms_key_id
# ==============================================================================

resource "google_kms_key_ring" "this" {
  project  = var.project_id
  name     = local.keyring_name
  location = var.region
}

resource "google_kms_crypto_key" "keys" {
  for_each = var.keys

  name            = each.key
  key_ring        = google_kms_key_ring.this.id
  purpose         = each.value.purpose
  rotation_period = each.value.rotation_period

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = each.value.protection_level
  }

  labels = local.common_labels

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_binding" "bindings" {
  for_each = {
    for binding in flatten([
      for key_name, key_cfg in var.keys : [
        for idx, b in key_cfg.iam_bindings : {
          unique_id = "${key_name}/${idx}"
          key_name  = key_name
          role      = b.role
          member    = b.member
        }
      ]
    ]) : binding.unique_id => binding
  }

  crypto_key_id = google_kms_crypto_key.keys[each.value.key_name].id
  role          = each.value.role
  members       = [each.value.member]
}
