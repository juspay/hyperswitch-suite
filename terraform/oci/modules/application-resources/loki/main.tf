# Chunk bucket

# Tenancy-wide read-only singleton; required as an explicit argument by every
# Object Storage resource.
data "oci_objectstorage_namespace" "this" {}

resource "oci_objectstorage_bucket" "chunks" {
  count = var.create_bucket ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = local.bucket_name

  versioning   = var.bucket_versioning_enabled ? "Enabled" : "Disabled"
  storage_tier = var.bucket_storage_tier

  # Explicitly NoPublicAccess, not exposed as a variable - a log-chunk store is
  # private in every environment.
  access_type = "NoPublicAccess"

  # No sse_algorithm to port: Object Storage encrypts every object with AES-256
  # unconditionally, so kms_key_id stays unset.

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # `force_destroy` has no counterpart: `oci_objectstorage_bucket` has no such
  # argument in provider 9.0.0 and a bucket containing objects cannot be deleted
  # by the resource (API returns 409). Teardown is two steps:
  #   oci os object bulk-delete --bucket-name <name> --namespace <namespace>
  #   terraform destroy
}

# Chunk expiry

# A separate resource on OCI, not an inline block on the bucket - a structural
# difference, not a capability gap.
resource "oci_objectstorage_object_lifecycle_policy" "chunks" {
  count = var.create_bucket && length(local.lifecycle_rules) > 0 ? 1 : 0

  namespace = data.oci_objectstorage_namespace.this.namespace
  bucket    = oci_objectstorage_bucket.chunks[0].name

  dynamic "rules" {
    for_each = local.lifecycle_rules

    content {
      name        = rules.value.name
      action      = rules.value.action
      time_amount = rules.value.time_amount
      time_unit   = rules.value.time_unit
      is_enabled  = true
    }
  }
}

# NOT in this module:
# 1. The bucket-notification hook. AWS's `s3.event_notifications` exists in the
#    variable surface but NOTHING turns it on in the one live unit (zero live
#    consumers). Its OCI translation is not free: `oci_events_rule` cannot target
#    the Queue service, so the nearest path runs through Streaming's Kafka
#    endpoint, which authenticates with a static user-bound OCI auth token - an
#    identity-model exception this module has no reason to import. If a consumer
#    ever needs it, the pattern is built and commented in
#    `application-resources/vector/notification.tf`.
# 2. The cross-module security rule. See network.tf.
