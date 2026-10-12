# =============================================================================
# Notifications (ONS) - the OCI counterpart of aws/modules/composition/sns.
#
# Check sheet: hyperswitch-infra/docs/multi-cloud-parity/oci/modules/sns.md
# Parity headline recorded there: 3 FULL / 1 SUBSTITUTE / 4 NONE.
#
# The platform's alert-fanout layer. Its whole reason to exist is to be the
# `destinations` of the `monitoring` module's alarms - the OCI equivalent of
# cloudwatch's alarm_actions pointing at sns_topic_arns. Every subscription in
# every AWS live root reviewed is protocol = "email"; nothing else is wired.
#
# NOTE ON THE GCP PRECEDENT: gcp/modules/composition/pubsub is NOT the analogue.
# Pub/Sub is a message queue for application eventing; GCP's alarm destination is
# google_monitoring_notification_channel, folded into cloud-monitoring. OCI is
# shaped like AWS here (a separate notification service), so this module exists
# where GCP has none.
# =============================================================================

resource "oci_ons_notification_topic" "this" {
  for_each = local.topics

  compartment_id = var.compartment_id
  name           = each.value.name
  description    = each.value.description

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags

  # ---------------------------------------------------------------------------
  # FOUR AWS ARGUMENTS WITH NO COUNTERPART HERE. All four are unset in every AWS
  # live root reviewed, so nothing in use is being dropped - but "unused" is not
  # "absent", and the distinction is what these comments record.
  #
  #   fifo_topic / content_based_deduplication   feature 2, NONE.
  #     ONS has no ordering guarantee and no dedup argument. If ordered,
  #     exactly-once-ish delivery is ever needed, the right question is "should
  #     this be OCI Queue instead", not "how do we bolt ordering onto ONS" -
  #     Notifications was never a queue product on either cloud.
  #
  #   kms_master_key_id                          feature 3, NONE.
  #     No CMEK argument on the topic. Whether Oracle-managed encryption is the
  #     only option, or CMEK exists tenancy-wide, is check sheet open question 2.
  #     Payloads here are alarm bodies (metric names, thresholds, runbook text),
  #     not customer data, which is why this is low-urgency.
  #
  #   aws_sns_topic_policy                       feature 6, NONE.
  #     No inline document controlling who may publish or subscribe. Unlike
  #     container-registry and file-storage - where the substitute is a
  #     confirmed compartment-level IAM policy - the Notifications IAM verb set
  #     was NOT looked up, so no substitute is offered here. Guessing at verbs
  #     and shipping a policy resource would be worse than the gap. Check sheet
  #     open question 1 must be answered before this becomes SUBSTITUTE, and the
  #     gate should not be convened on it until then.
  #
  #   aws_sns_topic_data_protection_policy       feature 7, NONE - EXPLICIT DROP.
  #     Confirmed with high confidence: a provider-wide search for `ons` returns
  #     exactly two resources, notification_topic and subscription. There is no
  #     third Notifications resource of any kind. AWS's PII detection/redaction
  #     of message bodies before delivery has nothing to substitute with.
  #     Per framework.md section 2's wording for a NONE verdict, this is the
  #     explicit-drop case: zero current usage, so there is no consumer to design
  #     a mitigation for. The responsibility moves to the PUBLISHER - do not put
  #     sensitive data in a notification body, because there is no delivery-time
  #     backstop on OCI. That is the assumption this comment exists to stop
  #     anyone making silently.
  #
  # Oracle gate: check sheet section 8 items 1-3, NOT YET CONSULTED.
  # ---------------------------------------------------------------------------
}

resource "oci_ons_subscription" "this" {
  for_each = local.subscriptions

  compartment_id = each.value.compartment_id
  topic_id       = oci_ons_notification_topic.this[each.value.topic_key].topic_id

  protocol = each.value.protocol
  endpoint = each.value.endpoint

  # See variables.tf: settable in oracle/oci 9.0.0, contrary to the check
  # sheet's read of it. Backoff retry configuration only - it does not close
  # feature 5, because filter_policy, raw_message_delivery and redrive_policy
  # still have no counterpart.
  delivery_policy = each.value.delivery_policy

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags

  # ---------------------------------------------------------------------------
  # FEATURE 5 - SUBSCRIPTION-LEVEL DELIVERY/FILTER OPTIONS: SUBSTITUTE.
  #
  # Three AWS arguments have nothing to map to: filter_policy (subscribe to a
  # subset of messages by attribute match), raw_message_delivery, and
  # redrive_policy (a dead-letter queue for undeliverable notifications).
  # confirmation_timeout_in_minutes also has no settable counterpart.
  #
  # The substitute is architectural and, usefully, is already how this fleet is
  # built: route by SEPARATE TOPICS PER SEVERITY rather than by subscription
  # filters. The AWS cloudwatch module's `sns_topic_arns` map is keyed by
  # severity, one topic per level, and the OCI `monitoring` module's
  # `destinations` map keeps that shape. So the existing design routes around
  # this gap rather than depending on it, and nothing needs redesigning.
  #
  # NOTE ON CONFIRMATION: like SNS, an OCI subscription is created PENDING and
  # delivers nothing until the endpoint owner confirms. The `state` output is
  # how to check; the smoke test is watching it move PENDING -> ACTIVE.
  # ---------------------------------------------------------------------------
}
