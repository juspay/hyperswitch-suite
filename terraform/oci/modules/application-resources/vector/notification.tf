# =============================================================================
# The event pipeline (check sheet feature 5, SUBSTITUTE - section 4.4)
# =============================================================================
# THE HARDEST FINDING IN THIS MODULE'S CHECK SHEET, IMPLEMENTED AT THE POINT OF
# DIVERGENCE.
#
# WHAT AWS DOES
#   aws_sqs_queue.this               a durable queue: 14-day retention, 20 s
#                                    long polling, 300 s visibility timeout
#   aws_sqs_queue_policy.this        a RESOURCE policy naming s3.amazonaws.com
#                                    as principal, scoped by aws:SourceArn
#   aws_s3_bucket_notification.this  s3:ObjectCreated:* -> that queue
#   aws_iam_policy.sqs_policy        the producer-side grant
#
# Vector's upstream `aws_s3` source is built around this: it consumes S3 objects
# VIA SQS notification messages and has no "list the bucket" mode. The queue is
# not incidental plumbing, it is the mechanism the application expects.
#
# WHAT OCI CANNOT DO
#   `oci_events_rule.actions.action.action_type` accepts exactly three values -
#   ONS (Notifications), OSS (Streaming), FAAS (Functions). QUEUE IS NOT A VALID
#   EVENTS TARGET. Verified directly against the provider 9.0.0 resource schema,
#   not asserted. There is also no `oci_objectstorage_bucket_notification`
#   resource: the bucket carries only a boolean (`object_events_enabled`,
#   main.tf), and routing is entirely the Events service's job.
#
#   So the AWS shape has no direct counterpart. The nearest wireable pipeline is
#   the one below:
#
#     bucket (object_events_enabled) -> Events rule (OSS) -> Streaming stream
#         -> Vector's `kafka` source over the Kafka-compatible endpoint
#
# FOUR DELIVERY-SEMANTICS CHANGES, none of them configuration:
#
#   Redelivery unit   SQS redelivers ONE message after visibility_timeout. A
#                     Kafka-protocol consumer resumes from its last COMMITTED
#                     OFFSET and reprocesses everything since - an offset RANGE,
#                     which can be many records. Anyone reasoning about this
#                     with a queue-shaped mental model will be surprised by a
#                     crash reprocessing a range instead of a message.
#   Retention         SQS: 60 s to 14 days, and this module's AWS default IS the
#                     14-day maximum. Streaming: 24-168 hours. The backlog
#                     headroom halves.
#   Dead letters      SQS has a redrive policy to a second queue. STREAMING HAS
#                     NO DEAD-LETTER CONCEPT AT ALL - a poison record sits at
#                     its offset and a naive consumer either blocks or must be
#                     coded to skip it. (OCI Queue does have a native DLQ, but
#                     Queue cannot receive this event in the first place, so
#                     that story is unreachable here.)
#   Ordering          SQS standard: none. Streaming with partitions = 1:
#                     per-partition FIFO - strictly BETTER, at the cost of
#                     capping consumer parallelism at one.
#
# AND THE ONE THAT NEEDS SIGNING OFF: THE IDENTITY BREAK.
#   Streaming's Kafka-compatible endpoint authenticates with SASL/PLAIN only -
#   username `<tenancy-name>/<user>/<stream-pool-OCID>`, password an OCI AUTH
#   TOKEN bound to an OCI USER, consulting no `request.principal.*` condition.
#   Vector's `kafka` source supports that shape and no other, and Vector has no
#   `oci_object_storage` source. Consuming this pipeline therefore CANNOT be
#   done under pure workload identity; it needs the one documented exception to
#   identity-model.md section 3.1, bounded as described on
#   `auth_token_vault_secret_id` in variables.tf: a dedicated least-privilege
#   user, the token held in OCI Vault and never in Terraform, relayed into the
#   pod by external-secrets-operator, owned and rotated.
#
#   The alternative that keeps the identity model whole is to not build this at
#   all (`create_notification = false`) and poll Object Storage under workload
#   identity instead - the object grant is already there. Push becomes poll, and
#   configuration becomes custom code.
#
#   Check sheet section 8 item 1 calls this the highest-value gate item in the
#   loki/vector/grafana trio. ORACLE GATE NOT YET CONSULTED. Nothing here is
#   enabled by default.
#
# `aws_sqs_queue_policy` HAS NO COUNTERPART AND NEEDS NONE. There is no
# resource-scoped access policy for Streaming or Queue - access is IAM-only -
# and the Events service delivers into the stream using its OWN service
# identity, not the consuming workload's, so there is no producer-side grant for
# this module to hold either.
# =============================================================================

resource "oci_streaming_stream" "events" {
  count = var.create_notification ? 1 : 0

  name       = local.stream_name
  partitions = var.stream_partitions

  # Exactly one of these is set. A pool is worth creating (or reusing) when the
  # SASL username needs a stable, non-default pool OCID or when the endpoint
  # must be private.
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
  # unconditionally: an Events rule is COMPARTMENT-scoped, unlike an S3
  # notification config which is attached to a bucket, so without it this rule
  # fires for every object-storage event in the compartment subtree - which in
  # this compartment means five vector buckets plus loki's plus hyperswitch's
  # two. Not a security hole; a firehose, in a log pipeline whose job is to
  # prevent exactly that.
  #
  # OPEN (check sheet section 9 Q1): the `data` filter's grammar is documented
  # only as "a JSON string containing additional event data filters", with no
  # formal reference. Verify empirically - two buckets in one compartment, a
  # rule filtered to A, confirm it never fires for B - before trusting the
  # scoping.
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
