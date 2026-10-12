# notifications

OCI Notifications (ONS): topics and their subscriptions. The alert-fanout layer
the `monitoring` module's alarms point at.

Counterpart of `terraform/aws/modules/composition/sns`. Parity analysis:
`hyperswitch-infra/docs/multi-cloud-parity/oci/modules/sns.md`
(3 FULL / 1 SUBSTITUTE / 4 NONE).

There is no GCP counterpart module. GCP's alarm destinations are
`google_monitoring_notification_channel`, folded into `cloud-monitoring`;
`gcp/modules/composition/pubsub` is a message queue, not a notification product,
and is not the precedent for this. OCI is shaped like AWS here.

## Two resources, and that is the whole service

A provider-wide search for `ons` returns exactly `oci_ons_notification_topic`
and `oci_ons_subscription`. Anything you are looking for that is not one of
those two does not exist in this service.

## Protocols

`CUSTOM_HTTPS`, `EMAIL`, `HTTPS`, `ORACLE_FUNCTIONS`, `PAGERDUTY`, `SLACK`,
`SMS`.

- `EMAIL` is the only one any AWS live root uses today.
- `PAGERDUTY` and `SLACK` are **native**, with no SNS equivalent (SNS needs
  Chatbot or a Lambda subscriber). A capability the port makes available; not
  one it needs.
- There is **no** SQS equivalent (queue fan-out is OCI Queue's job) and no
  direct Lambda equivalent (`ORACLE_FUNCTIONS` is the nearest).

Subscriptions are created `PENDING` and deliver nothing until the endpoint owner
confirms - same as SNS. Watch the `state` field in the `subscriptions` output.

## What this module does not have, and why

| AWS feature | Status | Note |
|---|---|---|
| `fifo_topic` / `content_based_deduplication` | **NONE** | No ordering or dedup concept. Unset on AWS today. |
| `kms_master_key_id` | **NONE** | No CMEK argument on the topic. Unset on AWS today. |
| `aws_sns_topic_policy` | **NONE** | No topic policy, and unlike the other sheets, **no confirmed IAM substitute either** - the Notifications verb set was not looked up. Not guessed at. |
| `aws_sns_topic_data_protection_policy` | **NONE, explicit drop** | No mitigation anywhere on the service. PII must not be put in a notification body - there is no delivery-time backstop. |
| `filter_policy` / `raw_message_delivery` / `redrive_policy` | SUBSTITUTE | Route with one topic per severity instead. The fleet already does this, so nothing needs redesigning. |

One correction to the check sheet: `delivery_policy` on `oci_ons_subscription`
is **settable** (optional+computed) in `oracle/oci` 9.0.0, not read-only as the
sheet recorded. It is exposed. It carries backoff retry configuration only and
does not close the feature-5 gap.

## Oracle gate

Not yet consulted. Check sheet section 8: the data-protection drop, the
FIFO/KMS pair (bundle them), and topic access policy - which should **not** go
to the gate until open question 1 (does OCI IAM have Notifications
publish/subscribe verbs?) is answered, because it is a fact-finding task, not a
decision.
