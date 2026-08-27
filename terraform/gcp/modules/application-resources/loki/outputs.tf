output "service_account_email" {
  description = "Email of Loki's Google service account"
  value       = module.workload_identity.service_account_email
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name"
  value       = module.workload_identity.k8s_service_account_name
}

output "chunks_bucket_name" {
  description = "Name of the chunks storage bucket"
  value       = module.chunks_bucket.name
}

output "bucket_notification_topic" {
  description = "Name of the Pub/Sub topic receiving bucket notifications, if enabled"
  value       = var.enable_bucket_notifications ? google_pubsub_topic.bucket_notifications[0].name : null
}
