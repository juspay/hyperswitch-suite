output "service_account_email" {
  description = "Email of Vector's Google service account"
  value       = module.workload_identity.service_account_email
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name"
  value       = module.workload_identity.k8s_service_account_name
}

output "logs_bucket_name" {
  description = "Name of the logs storage bucket, if created"
  value       = var.create_bucket ? module.logs_bucket[0].name : null
}

output "pubsub_topic" {
  description = "Name of the log-events Pub/Sub topic, if created"
  value       = var.create_queue ? google_pubsub_topic.log_events[0].name : null
}

output "pubsub_subscription" {
  description = "Name of the log-events pull subscription, if created"
  value       = var.create_queue ? google_pubsub_subscription.log_events[0].name : null
}
