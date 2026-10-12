# Log bucket

data "oci_objectstorage_namespace" "this" {}

resource "oci_objectstorage_bucket" "logs" {
  count = var.create_bucket ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = local.bucket_name

  versioning   = var.bucket_versioning_enabled ? "Enabled" : "Disabled"
  storage_tier = var.bucket_storage_tier
  access_type  = "NoPublicAccess"

  # This boolean is only half of the notification wiring: it turns event
  # EMISSION on for the bucket. Routing is entirely the Events service's job
  # (notification.tf); there is no bucket-notification resource.
  object_events_enabled = var.create_notification

  # Object Storage encrypts every object with AES-256 and it cannot be turned
  # off, so there is no sse_algorithm to port and kms_key_id is left unset.

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # `force_destroy = true` from the live vector-dr unit has no counterpart:
  # `oci_objectstorage_bucket` has no such argument in provider 9.0.0 and the
  # API refuses to delete a bucket containing objects. Teardown is:
  #   oci os object bulk-delete --bucket-name <name> --namespace <namespace>
  #   terraform destroy
  # A procedure change - someone running `terraform destroy` expecting AWS's
  # one-step behaviour will get a 409.
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
