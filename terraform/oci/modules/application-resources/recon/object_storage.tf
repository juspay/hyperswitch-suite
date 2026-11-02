# Object Storage - recon settlement / ingestion files. AWS: `module.recon_bucket`.

# The Object Storage namespace is a read-only, tenancy-wide singleton assigned
# at tenancy creation. Every bucket resource requires it as an explicit argument;
# it is discovered, never chosen.
data "oci_objectstorage_namespace" "this" {}

resource "oci_objectstorage_bucket" "recon" {
  count = local.recon_bucket_create ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = local.recon_bucket_name

  versioning = coalesce(var.recon_bucket.versioning_enabled, true) ? "Enabled" : "Disabled"

  # Explicitly NoPublicAccess, not exposed as a variable: the AWS bucket blocks
  # every form of public access in every environment.
  access_type = "NoPublicAccess"

  storage_tier = coalesce(var.recon_bucket.storage_tier, "Standard")

  # Object Storage encrypts all objects with AES-256 by default and cannot be
  # turned off, so kms_key_id is left unset (matching the AWS bucket's SSE-S3).
  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # `oci_objectstorage_bucket` has no force_destroy argument in provider 9.0.0 -
  # a bucket containing objects cannot be deleted by the resource at all (the
  # API returns 409). Teardown:
  #   oci os object bulk-delete --bucket-name <name> --namespace <namespace>
  # then `terraform destroy`.
}
