# Output contract

output "policy_statements" {
  description = <<-EOT
    This instantiation's contribution to the ONE shared, environment-scoped
    `oci_identity_policy` owned by the `oke-workload-identity` unit. Rendered,
    normalised and sorted.

    THIS MODULE CREATES NO POLICY OBJECT. With
    five instantiations, this module is the widest contributor in the platform -
    concatenate all five lists into the one shared object rather than giving any
    of them a policy of its own.

    Expect `manage objects` (or `read objects` for a consumer-only stream)
    scoped to this stream's bucket, plus `use stream-pull` when the notification
    pipeline is on. READ THE `use stream-pull` NOTE IN locals.tf: it is correct
    IAM, and it is NOT what authorises Vector's Kafka client. See
    `kafka_uses_static_credential`.
  EOT
  value       = local.policy_statements
}

output "statement_count" {
  description = "Number of statements this instantiation contributes, against the shared policy object's hard 50-statement ceiling. Multiply by five before sizing headroom."
  value       = length(local.policy_statements)
}

output "authorized_workload" {
  description = "The (cluster_id, namespace, service_account) tuples this instantiation's statements authorise. Singular in spirit - one instantiation, one service account - but a list because cluster_ids is."
  value       = local.authorized_workloads
}

output "bucket_name" {
  description = "Log bucket name. Replaces AWS s3_bucket_id/_arn - OCI addresses a bucket by (namespace, name)."
  value       = one(oci_objectstorage_bucket.logs[*].name)
}

output "bucket_namespace" {
  description = "The tenancy's Object Storage namespace. No AWS counterpart, and Vector's own sink config needs it explicitly."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "bucket_object_events_enabled" {
  description = "Whether event emission is on for the bucket. Half of what AWS expressed as a single aws_s3_bucket_notification - the other half is the Events rule, which is a separate service."
  value       = one(oci_objectstorage_bucket.logs[*].object_events_enabled)
}

output "stream_id" {
  description = "OCID of the Streaming stream the Events rule delivers into. No AWS counterpart under this name - it stands in for the SQS queue, with different delivery semantics (notification.tf)."
  value       = one(oci_streaming_stream.events[*].id)
}

output "stream_messages_endpoint" {
  description = "Streaming messages endpoint. REGIONAL, unlike Pub/Sub and unlike an SQS queue URL's reachability story - a cross-region consumer needs a network path decided separately."
  value       = one(oci_streaming_stream.events[*].messages_endpoint)
}

output "stream_pool_id" {
  description = "OCID of the stream pool the stream landed in - the tenancy default when stream_pool_id was not supplied. Needed as the THIRD component of the Kafka SASL username, so it is part of the credential, not just placement."
  value       = one(oci_streaming_stream.events[*].stream_pool_id)
}

output "stream_retention_hours" {
  description = "Retention actually applied, in hours. Capped at 168 - AWS's SQS default of 14 days is not reachable on OCI Streaming."
  value       = one(oci_streaming_stream.events[*].retention_in_hours)
}

output "events_rule_id" {
  description = "OCID of the Events rule. Compartment-scoped, unlike an S3 notification config which is attached to a bucket - which is why locals.event_condition always renders a bucket-name filter."
  value       = one(oci_events_rule.object_created[*].id)
}

output "events_rule_condition" {
  description = "The rendered Events-rule condition JSON, including the mandatory bucket-name filter. Surfaced so a reviewer can confirm the rule is scoped to this bucket rather than to every object-storage event in the compartment subtree."
  value       = var.create_notification ? local.event_condition : null
}

output "kafka_connection" {
  description = <<-EOT
    Everything a Kafka client needs to consume this stream, EXCEPT the password.

    `security_protocol` and `sasl_mechanism` are constants because OCI
    Streaming's Kafka-compatible endpoint accepts nothing else. `username` is
    `<tenancy-name>/<oci-username>/<stream-pool-OCID>` - null unless
    `kafka_sasl_username` was supplied, since this module knows only the pool
    OCID of that triple.

    THE PASSWORD IS NOT HERE AND WILL NOT BE. It is an OCI auth token held in
    Vault; this module carries only the secret's OCID
    (`auth_token_vault_secret_id`), for an ExternalSecret to project.
  EOT
  value = var.create_notification ? {
    bootstrap_endpoint       = one(oci_streaming_stream.events[*].messages_endpoint)
    stream_id                = one(oci_streaming_stream.events[*].id)
    stream_pool_id           = one(oci_streaming_stream.events[*].stream_pool_id)
    topic                    = local.stream_name
    security_protocol        = "SASL_SSL"
    sasl_mechanism           = "PLAIN"
    username                 = var.kafka_sasl_username
    password_vault_secret_id = var.auth_token_vault_secret_id
    vector_source_type       = "kafka"
    partitions               = var.stream_partitions
    dead_letter_supported    = false
    redelivery_unit          = "offset-range"
    max_retention_hours      = 168
  } : null
}

output "kafka_uses_static_credential" {
  description = <<-EOT
    TRUE means this instantiation is consuming the event stream with a
    long-lived, user-bound OCI auth token rather than workload identity.

    THIS IS THE ONE DOCUMENTED EXCEPTION TO THE IDENTITY MODEL IN THE
    WHOLE APPLICATION SET, and it is surfaced as an output so it appears in the
    plan and in every consumer's state rather than being buried in a Helm value.
    It is not a defect in this module: OCI Streaming's Kafka endpoint
    authenticates with SASL/PLAIN only and consults no `request.principal.*`
    condition, and Vector has no OCI-SDK-based Object Storage source.

    False with `create_notification = true` means the pipeline is built but no
    credential is wired - the stream will fill and nothing will read it.
    False with `create_notification = false` is the identity-model-clean posture
    (poll under workload identity instead).
  EOT
  value       = local.uses_static_kafka_credential
}

output "auth_token_vault_secret_id" {
  description = "Echo of the Vault secret OCID holding the Kafka SASL auth token, for an ExternalSecret to project into the pod. The OCID only - this module never reads, stores or emits a credential value."
  value       = var.auth_token_vault_secret_id
}

output "cross_region_read_enabled" {
  description = "Whether cross-region read grants were emitted. PARTIAL: the IAM half is complete, the NETWORK half is not expressible here - Streaming is regional, so a public TLS endpoint or a DRG path must be decided separately."
  value       = local.cross_region_enabled
}

output "app_name" {
  description = "The logical log-stream name, echoed. What distinguishes this instantiation from its four siblings."
  value       = var.app_name
}

output "compartment_id" {
  description = "Compartment these resources live in, and the default location term of every statement emitted."
  value       = var.compartment_id
}

output "region" {
  description = "Region, echoed from the input."
  value       = var.region
}
