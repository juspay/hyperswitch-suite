# Data sources
data "aws_region" "current" {}

# SNS Topics
resource "aws_sns_topic" "topics" {
  for_each = var.topics

  name              = each.value.name
  display_name      = each.value.display_name
  kms_master_key_id = each.value.kms_master_key_id

  # FIFO Topic configuration
  fifo_topic                  = each.value.fifo_topic
  content_based_deduplication = each.value.content_based_deduplication

  tags = merge(local.common_tags, {
    Name = each.value.name
  })
}

# SNS Topic Subscriptions
resource "aws_sns_topic_subscription" "subscriptions" {
  for_each = merge([for topic_key, topic_val in var.topics : {
    for sub_key, sub_val in topic_val.subscriptions : "${topic_key}-${sub_key}" => merge(
      sub_val,
      { topic_key = topic_key }
    )
  }]...)

  topic_arn = aws_sns_topic.topics[each.value.topic_key].arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint

  # Optional configurations
  filter_policy                   = each.value.filter_policy
  raw_message_delivery            = each.value.raw_message_delivery
  redrive_policy                  = each.value.redrive_policy
  delivery_policy                 = each.value.delivery_policy
  endpoint_auto_confirms          = each.value.endpoint_auto_confirms
  confirmation_timeout_in_minutes = each.value.confirmation_timeout_in_minutes
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "policies" {
  for_each = { for k, v in var.topics : k => v if v.policy != null }

  arn    = aws_sns_topic.topics[each.key].arn
  policy = each.value.policy
}

# SNS Topic Data Protection Policy
resource "aws_sns_topic_data_protection_policy" "data_protection_policies" {
  for_each = { for k, v in var.topics : k => v if v.data_protection_policy != null }

  arn    = aws_sns_topic.topics[each.key].arn
  policy = each.value.data_protection_policy
}
