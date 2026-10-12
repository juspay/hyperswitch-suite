# The event pipeline
# The OCI substitute for the S3-notification -> SQS shape: bucket (event
# emission) -> Events rule (OSS) -> Streaming stream -> Vector's `kafka` source.
#
# This path is the one documented exception to the platform's identity model:
# Streaming's Kafka endpoint authenticates with SASL/PLAIN using a user-bound
# OCI auth token, consulting no request.principal.* condition, and Vector has no
# OCI Object Storage source. It carries a static credential handled exactly as
# described on `auth_token_vault_secret_id` (Vault OCID only, relayed by
# external-secrets-operator). The push path also changes delivery semantics vs
# SQS: offset-range redelivery, 24-168 h retention, no dead-letter concept, and
# per-partition FIFO at partitions = 1. Alternatively leave create_notification
# false and poll the bucket under workload identity.

resource "oci_streaming_stream" "events" {
  count = var.create_notification ? 1 : 0

  name       = local.stream_name
  partitions = var.stream_partitions

  # Exactly one of these is set. A pool is worth creating/reusing when the SASL
  # username needs a stable, non-default pool OCID or the endpoint must be private.
  compartment_id = var.stream_pool_id == null ? var.compartment_id : null
  stream_pool_id = var.stream_pool_id

  retention_in_hours = var.stream_retention_hours

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_events_rule" "object_created" {
  count = var.create_notification ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-${var.app_name}-object-created"
  description    = "Object Storage create events on ${local.bucket_name} -> Streaming. The OCI substitute for aws_s3_bucket_notification -> SQS; see notification.tf."
  is_enabled     = true

  # See locals.event_condition. The bucket-name filter is rendered
  # unconditionally: an Events rule is COMPARTMENT-scoped, not attached to a
  # bucket, so without it the rule fires for every object-storage event in the
  # compartment subtree - five vector buckets plus loki's plus hyperswitch's two.
  # Not a security hole; a firehose, in a log pipeline whose job is to prevent that.
  condition = local.event_condition

  actions {
    actions {
      action_type = "OSS"
      is_enabled  = true
      stream_id   = oci_streaming_stream.events[0].id
      description = "Deliver object-create events to the ${local.stream_name} stream."
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = var.create_bucket
      error_message = "create_notification requires create_bucket - the Events rule filters on this module's own bucket name, and object_events_enabled is set on that bucket. To watch a bucket owned elsewhere, put the rule in the module that owns it."
    }
  }
}
