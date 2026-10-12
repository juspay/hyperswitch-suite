# vector (OCI)

Log-stream pipeline: an evented bucket piped through OCI Streaming into Vector's
Kafka source, with a notification path that is the one identity-model exception
in the platform.

Instantiated **once per logical log stream**, not once per cluster — each
stream keeps its own bucket, stream and statement set. Merging them would give
all streams each other's bucket access.

## The one identity-model exception

`create_notification = true` builds:

```
bucket (object_events_enabled) -> oci_events_rule (OSS) -> oci_streaming_stream
    -> Vector's `kafka` source, SASL_SSL / PLAIN
```

`oci_events_rule` accepts exactly `ONS`, `OSS`, `FAAS` — the OCI Queue service
is not a valid Events target, so the S3-notification-to-SQS shape has no direct
counterpart. Streaming's Kafka endpoint authenticates with SASL/PLAIN only:
username `<tenancy-name>/<user>/<stream-pool-OCID>`, password an OCI **auth
token** bound to an OCI user, and Vector has no `oci_object_storage` source.

The exception is bounded rather than hidden:

- The token is **never** an input. Only `auth_token_vault_secret_id` (a Vault
  secret OCID) is accepted. This module creates no user, no auth token and no
  secret, and never sees a credential value.
- Mint a **dedicated, least-privilege** OCI user. Auth tokens authenticate as
  the whole user everywhere it has grants.
- Relay it into the pod with `external-secrets-operator`, which itself runs
  under workload identity.
- `kafka_uses_static_credential` goes true, in the plan and in every consumer's
  outputs, so it cannot be taken quietly.

The alternative that keeps the identity model whole: leave
`create_notification = false` and poll Object Storage under workload identity —
push becomes poll, configuration becomes custom code.

## Four semantics changes versus the AWS (SQS) shape

| | AWS (SQS, as configured) | OCI (Events -> Streaming) |
|---|---|---|
| Redelivery unit | one message, after `visibility_timeout` | an **offset range** from the last commit |
| Retention | 14 days | **24-168 hours** |
| Dead letters | redrive to a second queue | **none** — a poison record sits at its offset |
| Ordering | none | per-partition FIFO at `partitions = 1`, at the cost of one consumer |

## The Events rule is compartment-scoped

An S3 notification config attaches to a bucket; an OCI Events rule is scoped to
a **compartment and its children**. Without a `data.additionalDetails.bucketName`
filter, one bucket's rule fires for every object-storage event in the subtree.
The filter is rendered unconditionally (`locals.event_condition`); verify its
grammar empirically before trusting the scoping.

## Other absences

- **No queue-shaped output.** A Streaming endpoint is not a queue URL. Emitting
  `sqs_queue_url`/`_arn` invites a queue-shaped mental model onto offset-based
  redelivery — use the `kafka_connection` output.
- **No resource-scoped access policy** for Streaming; access is IAM-only.
- **No `force_destroy`** — empty a non-empty bucket before destroy.
- **No customer-managed key** on the Object Storage side.
- **Nothing to attach** for `customer_managed_policy_arns` — folded into
  `shared_statements`; note revoking a shared grant is a fan-out edit across all
  callers.

## Cross-region is PARTIAL

OCI Streaming is **regional**. The grants this module emits are necessary but
not sufficient: a network path (public TLS endpoint, or a DRG to the primary
region's VCN) must be decided separately, and this module has no slot for it.