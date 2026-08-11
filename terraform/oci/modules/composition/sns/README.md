# sns (OCI) → OCI Notifications

OCI equivalent of `terraform/aws/modules/composition/sns`. Uses `oci_ons_notification_topic` /
`oci_ons_subscription`. No verified registry module exists - raw `oci` provider resources.

## Mapping notes

- OCI Notifications has no FIFO topic mode (AWS `fifo_topic`) — omitted.
- Protocol names differ: AWS `sqs`/`lambda`/`application`/`sms`/`email`/`https` → OCI `EMAIL`/`HTTPS`/`PAGERDUTY`/
  `SLACK`/`SMS` (no direct queue/function protocol — pair with OCI Streaming or Functions via an HTTPS webhook
  endpoint instead).
- Topic/data-protection policies (`aws_sns_topic_policy`, `aws_sns_topic_data_protection_policy`) map to IAM
  policies scoped to the `ons-topics` resource type, not a resource attached to the topic itself.
