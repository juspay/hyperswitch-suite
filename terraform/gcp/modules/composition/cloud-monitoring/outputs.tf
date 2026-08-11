output "notification_channel_ids" {
  description = "Map of notification channel key to its resource ID"
  value       = { for k, v in google_monitoring_notification_channel.this : k => v.id }
}

output "alert_policy_ids" {
  description = "Map of alert policy key to its resource ID"
  value       = { for k, v in google_monitoring_alert_policy.this : k => v.id }
}

output "log_metric_ids" {
  description = "Map of log-based metric key to its resource ID"
  value       = { for k, v in google_logging_metric.this : k => v.id }
}

output "dashboard_ids" {
  description = "Map of dashboard key to its resource ID"
  value       = { for k, v in google_monitoring_dashboard.this : k => v.id }
}

output "log_sink_writer_identities" {
  description = "Map of log sink key to its writer service-account identity, for granting it write access to the destination"
  value       = { for k, v in module.log_sinks : k => v.writer_identity }
}
