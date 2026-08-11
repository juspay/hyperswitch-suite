# ============================================================================
# OCI Notifications - equivalent of the AWS `sns` composition module
# (aws_sns_topic / aws_sns_topic_subscription). No verified registry module
# exists - raw oci provider resources.
# ============================================================================
resource "oci_ons_notification_topic" "topics" {
  for_each = var.topics

  compartment_id = var.compartment_id
  name           = each.value.name
  description    = each.value.description

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_ons_subscription" "subscriptions" {
  for_each = merge([for topic_key, topic_val in var.topics : {
    for sub_key, sub_val in topic_val.subscriptions : "${topic_key}-${sub_key}" => merge(
      sub_val,
      { topic_key = topic_key }
    )
  }]...)

  compartment_id = var.compartment_id
  topic_id       = oci_ons_notification_topic.topics[each.value.topic_key].id
  protocol       = each.value.protocol
  endpoint       = each.value.endpoint

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
