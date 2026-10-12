# Notifications (ONS): topics and subscriptions - the alert-fanout layer the monitoring module's alarms point at.

resource "oci_ons_notification_topic" "this" {
  for_each = local.topics

  compartment_id = var.compartment_id
  name           = each.value.name
  description    = each.value.description

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags
}

resource "oci_ons_subscription" "this" {
  for_each = local.subscriptions

  compartment_id = each.value.compartment_id
  topic_id       = oci_ons_notification_topic.this[each.value.topic_key].topic_id

  protocol = each.value.protocol
  endpoint = each.value.endpoint

  # Settable in oracle/oci 9.0.0 (see variables.tf) - backoff retry config only.
  delivery_policy = each.value.delivery_policy

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags
}
