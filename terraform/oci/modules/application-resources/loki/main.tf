# =============================================================================
# Chunk bucket (check sheet features 3 and 4)
# =============================================================================

# Tenancy-wide read-only singleton; no AWS counterpart, and required as an
# explicit argument by every Object Storage resource.
data "oci_objectstorage_namespace" "this" {}

resource "oci_objectstorage_bucket" "chunks" {
  count = var.create_bucket ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = local.bucket_name

  versioning   = var.bucket_versioning_enabled ? "Enabled" : "Disabled"
  storage_tier = var.bucket_storage_tier

  # AWS spends four hardcoded-true booleans (block_public_acls,
  # block_public_policy, ignore_public_acls, restrict_public_buckets) to reach
  # a posture OCI expresses as one enum whose default is already
  # NoPublicAccess. Stated so the posture is visible rather than inferred, and
  # not exposed as a variable - a log-chunk store is private in every
  # environment.
  access_type = "NoPublicAccess"

  # No `sse_algorithm` / `bucket_key_enabled` to port. Object Storage encrypts
  # every object with AES-256 unconditionally - "enabled by default and can't be
  # turned off" - which is at least as strong as the AWS module's SSE-S3 choice.
  # `is_bucket_key_enabled` only has meaning alongside a customer Vault key, and
  # AWS does not use one here, so neither does this.

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # ---------------------------------------------------------------------------
  # PARTIAL (check sheet feature 4). `force_destroy` - set by the live AWS unit
  # - has no counterpart: `oci_objectstorage_bucket` has no such argument in
  # provider 9.0.0, and a bucket containing objects cannot be deleted by the
  # resource at all (the API returns 409). It is omitted rather than accepted
  # and silently ignored. Dev-loop teardown becomes two steps:
  #   oci os object bulk-delete --bucket-name <name> --namespace <namespace>
  #   terraform destroy
  # This changes a teardown PROCEDURE, not a running capability. Same finding as
  # vector.md section 4.3.
  # ---------------------------------------------------------------------------
}

# -----------------------------------------------------------------------------
# Chunk expiry
# -----------------------------------------------------------------------------
# The live AWS unit's `lifecycle_rule = [{expiration.days = 365}]`. A separate
# resource on OCI rather than an inline block on the bucket - structural
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

# =============================================================================
# WHAT IS DELIBERATELY NOT IN THIS MODULE
# =============================================================================
#
# 1. THE BUCKET-NOTIFICATION HOOK (AWS feature 5, verdict SUBSTITUTE).
#
#    AWS's `aws_s3_bucket_notification.this` renders a caller-supplied list of
#    `{id, queue_arn, events, filter_prefix, filter_suffix}` objects onto the
#    bucket. It does NOT create the queue - it only wires notifications to a
#    queue ARN the caller already has. In the one live catalog instantiation
#    reviewed, `s3.event_notifications` is `[]`: the hook exists in the variable
#    surface and NOTHING TURNS IT ON.
#
#    It is not ported. Two reasons, and the second is the load-bearing one:
#
#    a. Zero live consumers. Carrying a dead knob is how a port accumulates
#       lies (database.md section 4.6's principle, applied).
#
#    b. The OCI translation is not free. `oci_events_rule.actions.action
#       .action_type` accepts exactly ONS, OSS and FAAS - Queue is not a valid
#       target - so the nearest wireable path is Object Storage event -> Events
#       rule -> Streaming stream, consumed over Streaming's Kafka-compatible
#       endpoint, which authenticates with SASL/PLAIN using a static,
#       user-bound OCI auth token. That is precisely the long-lived credential
#       identity-model.md section 3.1 rejects. Turning this on would import an
#       identity-model exception into a module that today has none.
#
#    If a consumer ever genuinely needs to know the moment a chunk lands, the
#    pattern is already built and commented in
#    `application-resources/vector/notification.tf` - copy it there, against a
#    real requirement, and take vector.md section 8 item 1's gate decision with
#    it. Check sheet loki.md section 4.3 and section 8 item 3; oracle gate NOT
#    YET CONSULTED, and this omission is the sheet's own recommendation, not a
#    ruling.
#
# 2. THE CROSS-MODULE SECURITY RULE. See network.tf.
# =============================================================================
