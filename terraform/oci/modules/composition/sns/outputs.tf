output "topic_ids" {
  value = { for k, v in oci_ons_notification_topic.topics : k => v.id }
}
