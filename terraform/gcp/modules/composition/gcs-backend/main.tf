# ============================================================================
# Terraform Backend Infrastructure (GCS)
# ============================================================================
# This module creates the backend infrastructure for Terraform on GCP:
#   - GCS bucket for state storage (versioned, uniform bucket-level access,
#     optional CMEK, optional retention policy)
#
# Unlike the AWS equivalent (composition/terraform-backend), no lock table is
# created: the GCS backend uses native object-generation locking, so a
# DynamoDB-style companion resource has no GCP equivalent and is intentionally
# omitted. See terraform/gcp/modules/README.md for the full mapping notes.
#
# Usage:
#   module "terraform_backend" {
#     source = "../../modules/composition/gcs-backend"
#
#     environment       = "dev"
#     project_name      = "hyperswitch"
#     project_id        = "hyperswitch-dev"
#     state_bucket_name = "hyperswitch-dev-terraform-state"
#   }
# ============================================================================

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
