# vector (OCI)

The OCI port of `terraform/aws/modules/application-resources/vector`.

Check sheet: `docs/multi-cloud-parity/oci/modules/vector.md`.

Instantiated **once per logical log stream**, not once per cluster. AWS has five
today (`vector-logging`, `vector-dr`, `vector-dr-consumer`,
`vector-hyperswitch-art`, `vector-ucs-deja`); that shape survives as five
instantiations of this module, each with its own bucket, stream and statement
set. Merging them would give all five streams each other's bucket access and has
no AWS evidence behind it. Oracle gate item, **not yet consulted**.

## The one identity-model exception in the platform

`create_notification = true` builds:

```
bucket (object_events_enabled) -> oci_events_rule (OSS) -> oci_streaming_stream
    -> Vector's `kafka` source, SASL_SSL / PLAIN
```

`oci_events_rule` accepts exactly `ONS`, `OSS`, `FAAS` - **the OCI Queue service
is not a valid Events target**, so the S3-notification-to-SQS shape has no direct
counterpart. Streaming's Kafka endpoint authenticates with SASL/PLAIN only:
username `<tenancy-name>/<user>/<stream-pool-OCID>`, password an OCI **auth
token** bound to an OCI user, consulting no `request.principal.*` condition.
Vector supports that shape and no other, and has no `oci_object_storage` source.

So this pipeline cannot be consumed under pure workload identity. The exception
is bounded rather than hidden:

- The token is **never** an input. Only `auth_token_vault_secret_id` - a Vault
  secret OCID - is accepted. This module creates no user, no auth token and no
  secret, and never sees a credential value.
- Mint a **dedicated, least-privilege** OCI user for this. Auth tokens
  authenticate as the whole user everywhere it has grants.
- Relay it into the pod with `external-secrets-operator`, which itself runs
  under workload identity.
- `kafka_uses_static_credential` goes true, in the plan and in every consumer's
  outputs, so it cannot be taken quietly.

The alternative that keeps the identity model whole: leave
`create_notification = false` and poll Object Storage under workload identity -
the object grant is already there. Push becomes poll; configuration becomes
custom code. Check sheet section 8 item 1 calls this the highest-value gate item
in the trio.

## Four semantics changes, none of them configuration

| | AWS (SQS, as configured) | OCI (Events -> Streaming) |
|---|---|---|
| Redelivery unit | one message, after `visibility_timeout` | an **offset range** from the last commit |
| Retention | 14 days (the module's default *is* the SQS max) | **24-168 hours**. Halved. |
| Dead letters | redrive to a second queue | **none**. A poison record sits at its offset. |
| Ordering | none | per-partition FIFO at `partitions = 1`, at the cost of one consumer |

## The Events rule is compartment-scoped

An S3 notification config is attached to a bucket; an OCI Events rule is scoped
to a **compartment and its children**. Without a
`data.additionalDetails.bucketName` filter, a rule for one bucket fires for every
object-storage event in the subtree - here, five vector buckets plus loki's plus
hyperswitch's two. The filter is rendered unconditionally
(`locals.event_condition`) rather than left to a caller. Its grammar is
documented only as "a JSON string containing additional event data filters";
verify empirically before trusting the scoping (check sheet section 9 Q1).

## Other absences

| AWS surface | Why |
|---|---|
| `sqs_queue_url` / `_arn` output | A Streaming endpoint is not a queue URL. Emitting one under a queue-shaped name invites a queue-shaped mental model onto offset-based redelivery. Use `kafka_connection`. |
| `aws_sqs_queue_policy` | No resource-scoped access policy exists for Streaming; access is IAM-only, and Events delivers under its own service identity so there is no producer-side grant to hold. |
| `force_destroy` | No such argument; a non-empty bucket cannot be deleted by the resource. |
| `sqs_cross_region.kms_key_arn` | No customer-managed key on the Object Storage side. |
| `customer_managed_policy_arns` | Nothing is attachable. Folded into `shared_statements` - note the cost shape changes: revoking a shared grant is a fan-out edit across five callers, not one detach. |

## Cross-region is PARTIAL, and the missing half is not IAM

On GCP this is genuinely just an IAM grant because Pub/Sub is global. OCI
Streaming is **regional**. The grants this module emits are necessary and not
sufficient: a network path (public TLS endpoint, or a DRG to the primary
region's VCN) must be decided separately, and this module has no slot for it.
