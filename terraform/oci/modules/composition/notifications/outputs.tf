# The monitoring module consumes `topic_ocids` as its per-severity `destinations`; keep the name stable.

output "topic_ocids" {
  description = "Map of topic key to OCID. Counterpart of AWS's topic_arns, and what the monitoring module's `destinations` takes. Note oci_monitoring_alarm allows ONE destination per destination service, so pass a single-element list."
  value       = { for k, v in oci_ons_notification_topic.this : k => v.topic_id }
}

output "topic_names" {
  description = "Map of topic key to ONS topic name"
  value       = { for k, v in oci_ons_notification_topic.this : k => v.name }
}

output "topic_ids" {
  description = "Map of topic key to the resource id. Identical in value to topic_ocids for this resource; kept because the AWS module exposes both topic_arns and topic_ids and consumers may read either."
  value       = { for k, v in oci_ons_notification_topic.this : k => v.id }
}

output "topic_api_endpoints" {
  description = "Map of topic key to the ONS publish/management endpoint URL. No AWS counterpart - useful for anything publishing to the topic outside Terraform."
  value       = { for k, v in oci_ons_notification_topic.this : k => v.api_endpoint }
}

output "subscriptions" {
  description = "Map of \"<topic>-<subscription>\" to its endpoint, protocol, topic OCID and state. `state` matters: a subscription is created PENDING and delivers nothing until confirmed."
  value = {
    for k, v in oci_ons_subscription.this : k => {
      endpoint = v.endpoint
      protocol = v.protocol
      topic_id = v.topic_id
      state    = v.state
    }
  }
}

output "subscription_ocids" {
  description = "Map of \"<topic>-<subscription>\" to subscription OCID. Counterpart of AWS's subscription_arns."
  value       = { for k, v in oci_ons_subscription.this : k => v.id }
}

output "region" {
  description = "OCI region identifier, passed through (an ONS topic exposes no region attribute)"
  value       = var.region
}
