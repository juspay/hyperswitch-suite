# SNS Topic Outputs
output "topic_arns" {
  description = "Map of topic keys to ARNs"
  value       = { for k, v in aws_sns_topic.topics : k => v.arn }
}

output "topic_names" {
  description = "Map of topic keys to names"
  value       = { for k, v in aws_sns_topic.topics : k => v.name }
}

output "topic_ids" {
  description = "Map of topic keys to topic IDs"
  value       = { for k, v in aws_sns_topic.topics : k => v.id }
}

output "subscriptions" {
  description = "Map of subscription keys to subscription details"
  value = {
    for k, v in aws_sns_topic_subscription.subscriptions :
    k => {
      arn       = v.arn
      endpoint  = v.endpoint
      protocol  = v.protocol
      topic_arn = v.topic_arn
    }
  }
}

output "subscription_arns" {
  description = "Map of subscription keys to subscription ARNs"
  value       = { for k, v in aws_sns_topic_subscription.subscriptions : k => v.arn }
}

output "topic_policies" {
  description = "Map of topic keys to their policies"
  value       = { for k, v in aws_sns_topic_policy.policies : k => v.policy }
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}
