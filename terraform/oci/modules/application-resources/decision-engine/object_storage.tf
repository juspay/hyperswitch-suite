# Object Storage - the module's own bucket

# Tenancy-wide, read-only singleton; required explicitly by every bucket resource.
data "oci_objectstorage_namespace" "this" {}

resource "oci_objectstorage_bucket" "this" {
  count = local.bucket_create ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = local.bucket_name

  versioning   = coalesce(var.bucket.versioning_enabled, true) ? "Enabled" : "Disabled"
  access_type  = "NoPublicAccess"
  storage_tier = coalesce(var.bucket.storage_tier, "Standard")

  # Object Storage encrypts every object with AES-256 and it cannot be turned
  # off, so kms_key_id stays unset (matching the SSE-S3 choice).

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # NOT here, and their absence is correct:
  #   force_destroy - no such argument in provider 9.0.0; a non-empty bucket
  #     cannot be deleted by the resource (409). Empty it first:
  #     oci os object bulk-delete --bucket-name <n> --namespace <ns>
  #   an Origin-Access-Control bucket policy - OCI has no first-party CDN to
  #     grant access to; a future CDN is a new architecture decision.
}

# Lifecycle rules
# A separate resource on OCI, unlike AWS's inline `lifecycle_rule` block on the
# bucket - a structural difference, not a capability gap.
resource "oci_objectstorage_object_lifecycle_policy" "this" {
  count = local.bucket_create && length(local.lifecycle_rules) > 0 ? 1 : 0

  namespace = data.oci_objectstorage_namespace.this.namespace
  bucket    = oci_objectstorage_bucket.this[0].name

  dynamic "rules" {
    for_each = local.lifecycle_rules

    content {
      name        = rules.value.name
      action      = rules.value.action
      time_amount = rules.value.time_amount
      time_unit   = try(rules.value.time_unit, "DAYS")
      is_enabled  = try(rules.value.is_enabled, true)
      target      = try(rules.value.target, null)

      dynamic "object_name_filter" {
        for_each = try(rules.value.object_name_filter, null) != null ? [rules.value.object_name_filter] : []

        content {
          inclusion_prefixes = object_name_filter.value.inclusion_prefixes
          inclusion_patterns = object_name_filter.value.inclusion_patterns
          exclusion_patterns = object_name_filter.value.exclusion_patterns
        }
      }
    }
  }
}
