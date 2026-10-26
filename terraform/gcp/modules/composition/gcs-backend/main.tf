# Terraform state backend: a versioned GCS bucket with uniform bucket-level
# access, optional CMEK and optional retention policy.
#
# No lock table is created - the GCS backend uses native object-generation
# locking, so there is no DynamoDB-style companion resource to provision.

module "state_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  project_id    = var.project_id
  name          = var.state_bucket_name
  location      = var.location
  storage_class = var.storage_class
  force_destroy = var.allow_destroy

  versioning               = true
  bucket_policy_only       = true
  public_access_prevention = "enforced"

  encryption = var.kms_key_id != null ? {
    default_kms_key_name = var.kms_key_id
  } : null

  retention_policy = var.retention_period_seconds != null ? {
    is_locked        = var.retention_policy_locked
    retention_period = var.retention_period_seconds
  } : null

  lifecycle_rules = var.lifecycle_rules

  labels = merge(
    local.common_labels,
    {
      "name"    = var.state_bucket_name
      "purpose" = "terraform-state"
    }
  )
}
