# =============================================================================
# Object Storage - the module's own bucket (check sheet feature 6, FULL)
# =============================================================================

# Tenancy-wide, read-only singleton. No AWS counterpart: S3 names are globally
# unique, OCI's are unique within this namespace, and every bucket resource
# needs it explicitly.
data "oci_objectstorage_namespace" "this" {}

resource "oci_objectstorage_bucket" "this" {
  count = local.bucket_create ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = local.bucket_name

  versioning   = coalesce(var.bucket.versioning_enabled, true) ? "Enabled" : "Disabled"
  access_type  = "NoPublicAccess"
  storage_tier = coalesce(var.bucket.storage_tier, "Standard")

  # Encryption has no toggle to port from the AWS module's `sse_algorithm`:
  # Object Storage encrypts every object with AES-256 and it "can't be turned
  # off". AWS chose SSE-S3 (Oracle-managed-key equivalent) for this bucket, so
  # kms_key_id stays unset and the port matches that choice rather than
  # silently upgrading it.

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # ---------------------------------------------------------------------------
  # NOT HERE, and their absence is correct rather than incomplete:
  #
  #   force_destroy  - no such argument on oci_objectstorage_bucket in provider
  #     9.0.0; a non-empty bucket cannot be deleted by the resource at all.
  #     Empty it first: oci os object bulk-delete --bucket-name <n> --namespace <ns>
  #
  #   an Origin-Access-Control bucket policy (AWS feature 7, verdict NONE) -
  #     OCI has no first-party CDN to grant access to. "CDN Interconnect" is a
  #     third-party Cloudflare peering arrangement, North America only, with no
  #     Terraform resource. Unused on AWS today, so zero blast radius; a future
  #     CDN requirement is a new architecture decision, not a parameter here.
  #     Check sheet section 4.1.
  # ---------------------------------------------------------------------------
}

# -----------------------------------------------------------------------------
# Lifecycle rules
# -----------------------------------------------------------------------------
# A SEPARATE resource on OCI, unlike AWS's inline `lifecycle_rule` block on the
# bucket module - a structural difference, not a capability gap. Carries the
# real AWS unit's 30-day noncurrent-version-expiration rule by default.
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
