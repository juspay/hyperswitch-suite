# notifications

OCI Notifications (ONS): topics and subscriptions — the alert-fanout layer the
`monitoring` module's alarms point at.

## Two resources

The service provides exactly `oci_ons_notification_topic` and
`oci_ons_subscription`.

## Protocols

`CUSTOM_HTTPS`, `EMAIL`, `HTTPS`, `ORACLE_FUNCTIONS`, `PAGERDUTY`, `SLACK`,
`SMS`. `PAGERDUTY` and `SLACK` are native. Subscriptions are created `PENDING`
and deliver nothing until the endpoint owner confirms; watch the `state` field
in the `subscriptions` output.

## What this module does not have, and why

- **No ordering, dedup, or CMEK** — `fifo_topic` / `content_based_deduplication`
  and `kms_master_key_id` have no OCI counterpart.
- **No topic policy** — no confirmed IAM substitute; the Notifications verb set
  is not asserted.
- **No data-protection policy** — PII must not be put in a notification body;
  there is no delivery-time backstop.
- **No filter / raw-delivery / redrive** — route with one topic per severity
  instead.
- `delivery_policy` on `oci_ons_subscription` is settable and carries backoff
  retry configuration only.