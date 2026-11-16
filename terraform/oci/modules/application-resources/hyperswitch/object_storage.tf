# =============================================================================
# Object Storage - dashboard themes + file uploads (check sheet features 4, 5)
# =============================================================================
# AWS: two independent `terraform-aws-modules/s3-bucket/aws` instantiations,
# each with its own `aws_iam_policy` attached to the role. Here the buckets are
# two plain resources and the permissions are two statements in locals.tf.

# The Object Storage namespace is a read-only, tenancy-wide singleton Oracle
# assigns at tenancy creation. It has no AWS counterpart - S3 bucket names are
# globally unique across all of AWS, OCI bucket names are unique only within
# this namespace - and every bucket resource requires it as an explicit
# argument. Not a variable: it is discovered, never chosen.
data "oci_objectstorage_namespace" "this" {}

resource "oci_objectstorage_bucket" "dashboard_themes" {
  count = local.dashboard_themes_create ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = local.dashboard_themes_bucket_name

  versioning = coalesce(var.dashboard_themes_bucket.versioning_enabled, true) ? "Enabled" : "Disabled"

  # AWS spends four booleans (block_public_acls, block_public_policy,
  # ignore_public_acls, restrict_public_buckets), all hardcoded true in the
  # nested module, to reach a posture OCI expresses as one enum whose default is
  # already NoPublicAccess. Stated explicitly so a reviewer sees the posture
  # rather than inferring it, and NOT exposed as a variable: a payments
  # platform's theme and upload buckets are private in every environment.
  access_type = "NoPublicAccess"

  storage_tier = coalesce(var.dashboard_themes_bucket.storage_tier, "Standard")

  # No `sse_algorithm` to port. Object Storage "encrypts all objects using
  # 256-bit AES... enabled by default and can't be turned off", which is at
  # least as strong as the AWS module's own SSE-S3/AES256 choice. The only
  # decision left would be who holds the master key; AWS chose Oracle's
  # equivalent (SSE-S3, not SSE-KMS) for these buckets, so this port makes the
  # matching choice and leaves kms_key_id unset.

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # ---------------------------------------------------------------------------
  # `force_destroy` IS DROPPED, NOT RENAMED (check sheet section 5's input
  # table; same finding as vector.md section 4.3).
  #
  # `oci_objectstorage_bucket` has no force_destroy-equivalent argument in
  # provider 9.0.0. A bucket containing objects cannot be deleted by the
  # resource at all - the API returns 409. Accepting a variable and silently
  # ignoring it would be worse than not having one. To tear this down:
  #   oci os object bulk-delete --bucket-name <name> --namespace <namespace>
  # then `terraform destroy`.
  # ---------------------------------------------------------------------------
}

resource "oci_objectstorage_bucket" "file_uploads" {
  count = local.file_uploads_create ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = local.file_uploads_bucket_name

  versioning   = coalesce(var.file_uploads_bucket.versioning_enabled, true) ? "Enabled" : "Disabled"
  access_type  = "NoPublicAccess"
  storage_tier = coalesce(var.file_uploads_bucket.storage_tier, "Standard")

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
