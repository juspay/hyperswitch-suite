data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_id
}

# ============================================================================
# Object Storage bucket for Terraform state - equivalent of the AWS
# `terraform-backend` composition module's S3 bucket. Point Terraform's
# `backend "s3"` block at this bucket's S3 Compatibility API endpoint
# (https://<namespace>.compat.objectstorage.<region>.oraclecloud.com) to use
# it as a drop-in S3-compatible backend, including native state locking on
# Terraform >= 1.10 (no DynamoDB-equivalent lock table required - see
# var.create_lock_table).
# ============================================================================
resource "oci_objectstorage_bucket" "state" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = var.state_bucket_name

  versioning = "Enabled"

  kms_key_id = var.kms_key_id

  freeform_tags = merge(var.freeform_tags, {
    Environment = var.environment
    Purpose     = "terraform-state"
    ManagedBy   = "terraform-bootstrap"
    Project     = var.project_name
  })
  defined_tags = var.defined_tags
}

# ============================================================================
# Optional NoSQL table for state locking (equivalent of AWS DynamoDB lock
# table) - see var.create_lock_table description for when this is actually
# needed.
# ============================================================================
resource "oci_nosql_table" "lock" {
  count = var.create_lock_table ? 1 : 0

  compartment_id = var.compartment_id
  name           = coalesce(var.lock_table_name, "${var.state_bucket_name}-lock")

  ddl_statement = "CREATE TABLE ${coalesce(var.lock_table_name, "${var.state_bucket_name}-lock")} (LockID STRING, Info STRING, PRIMARY KEY(LockID))"

  table_limits {
    max_read_units     = 10
    max_write_units    = 10
    max_storage_in_gbs = 1
    capacity_mode      = "ON_DEMAND"
  }

  freeform_tags = merge(var.freeform_tags, {
    Environment = var.environment
    Purpose     = "terraform-state-lock"
    ManagedBy   = "terraform-bootstrap"
    Project     = var.project_name
  })
  defined_tags = var.defined_tags
}
