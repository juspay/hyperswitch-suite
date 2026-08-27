output "topic" {
  description = "Name of the created topic"
  value       = module.pubsub.topic
}

output "topic_id" {
  description = "Fully qualified ID of the topic"
  value       = module.pubsub.id
}

output "subscription_names" {
  description = "Map of all created subscription names"
  value       = module.pubsub.subscription_names
}

output "subscription_paths" {
  description = "Map of all created subscription fully qualified paths"
  value       = module.pubsub.subscription_paths
}
