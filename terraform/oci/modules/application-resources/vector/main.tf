# =============================================================================
# Log bucket (check sheet features 3 and 4)
# =============================================================================

data "oci_objectstorage_namespace" "this" {}

resource "oci_objectstorage_bucket" "logs" {
  count = var.create_bucket ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = local.bucket_name

  versioning   = var.bucket_versioning_enabled ? "Enabled" : "Disabled"
  storage_tier = var.bucket_storage_tier
  access_type  = "NoPublicAccess"

  # ---------------------------------------------------------------------------
  # This boolean IS the S3-bucket-notification replacement, and it is only half
  # of it. On AWS, `aws_s3_bucket_notification` both turns emission on and says
  # where the events go. On OCI those are two different services: this flag
  # turns event EMISSION on for the bucket, and routing is entirely the Events
  # service's job (notification.tf). There is no
  # `oci_objectstorage_bucket_notification` resource, and no per-bucket
  # destination configuration anywhere.
  # ---------------------------------------------------------------------------
  object_events_enabled = var.create_notification

  # No `sse_algorithm` / `bucket_key_enabled` to port: Object Storage encrypts
  # every object with AES-256 and it cannot be turned off. `is_bucket_key_enabled`
  # only means anything alongside a customer Vault key, which AWS does not use
  # here either.

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # ---------------------------------------------------------------------------
  # PARTIAL (check sheet section 4.3). `force_destroy = true`, set by the live
  # `vector-dr` unit, has no counterpart: no such argument exists on
  # `oci_objectstorage_bucket` in provider 9.0.0, and the API refuses to delete
  # a bucket containing objects. Omitted rather than accepted and ignored.
  # Dev-loop teardown becomes:
  #   oci os object bulk-delete --bucket-name <name> --namespace <namespace>
  #   terraform destroy
  # A procedure change, not a capability loss - but someone will run
  # `terraform destroy` expecting AWS's one-step behaviour and get a 409.
  # ---------------------------------------------------------------------------
}

resource "oci_objectstorage_object_lifecycle_policy" "logs" {
  count = var.create_bucket && length(var.bucket_lifecycle_rules) > 0 ? 1 : 0

  namespace = data.oci_objectstorage_namespace.this.namespace
  bucket    = oci_objectstorage_bucket.logs[0].name

  dynamic "rules" {
    for_each = var.bucket_lifecycle_rules

    content {
      name        = rules.value.name
      action      = rules.value.action
      time_amount = rules.value.time_amount
      time_unit   = rules.value.time_unit
      is_enabled  = rules.value.is_enabled
      target      = rules.value.target

      dynamic "object_name_filter" {
        for_each = rules.value.object_name_filter != null ? [rules.value.object_name_filter] : []

        content {
          inclusion_prefixes = object_name_filter.value.inclusion_prefixes
          inclusion_patterns = object_name_filter.value.inclusion_patterns
          exclusion_patterns = object_name_filter.value.exclusion_patterns
        }
      }
    }
  }
}
