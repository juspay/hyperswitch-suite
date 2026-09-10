# Optional CMEK key for Spanner database encryption.
#
# Spanner attaches CMEK per DATABASE, not per instance - unlike AlloyDB, where
# the key is a cluster-level property.
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

# ============================================================================
# CMEK access for the Spanner service agent
# ============================================================================
# A CMEK-encrypted Spanner database is encrypted by the Spanner SERVICE AGENT,
# not by the caller's credentials, so the agent - not the operator, and not the
# workload - is the principal that must hold encrypt/decrypt on the key.
# Without this grant the database creation fails with a KMS permission error
# that names the agent address.
#
# This mirrors composition/alloydb's kms.tf, where the equivalent omission was
# confirmed live on 2026-09-03: the CLUSTER created fine and the INSTANCE then
# failed part-way through, which is a confusing place to land.
#
# google_project_service_identity (rather than deriving the address from
# data.google_project) so a clean-room apply also WORKS: the agent only exists
# once it has been provisioned for the project, and this creates it if missing
# instead of granting a role to a principal that does not resolve yet - which
# Terraform rejects outright.
resource "google_project_service_identity" "spanner" {
  provider = google-beta

  count = local.any_cmek ? 1 : 0

  project = var.project_id
  service = "spanner.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "spanner_service_agent" {
  # One grant per DISTINCT key, since databases may each carry their own.
  for_each = local.any_cmek ? toset([
    for k, d in local.databases : d.kms_key_name if d.kms_key_name != null
  ]) : toset([])

  crypto_key_id = each.value
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.spanner[0].email}"
}
