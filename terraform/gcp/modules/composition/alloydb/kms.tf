# Optional CMEK key for AlloyDB cluster encryption
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
# CMEK access for the AlloyDB service agent
# ============================================================================
# A CMEK-encrypted AlloyDB instance is created by the AlloyDB SERVICE AGENT,
# not by the caller's credentials, so the agent - not the operator, and not
# the workload - is the principal that must hold encrypt/decrypt on the key.
# Without this the cluster still creates (the API validates the key lazily
# there) and then the INSTANCE fails part-way through creation with:
#
#   Error code 9 ... Invalid resource state for ".../cryptoKeys/<key>":
#   KMS key cannot be accessed. Grant the Cloud KMS Encrypter / Decrypter
#   role to "service-<PROJECT_NUMBER>@gcp-sa-alloydb.iam.gserviceaccount.com"
#
# which is a confusing failure to land on, because everything up to that
# point succeeded. Confirmed live on 2026-09-03 against a first apply of
# composition/locker.
#
# google_project_service_identity (rather than deriving the address from
# data.google_project) so a clean-room apply also WORKS: the agent only
# exists once it has been provisioned for the project, and this creates it
# if it is missing instead of granting a role to a principal that does not
# resolve yet - which Terraform rejects outright.
resource "google_project_service_identity" "alloydb" {
  provider = google-beta

  count = local.kms_key_name != null ? 1 : 0

  project = var.project_id
  service = "alloydb.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "alloydb_service_agent" {
  count = local.kms_key_name != null ? 1 : 0

  crypto_key_id = local.kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.alloydb[0].email}"
}
