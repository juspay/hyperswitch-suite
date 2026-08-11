output "alarm_ids" {
  value = { for k, v in oci_monitoring_alarm.this : k => v.id }
}

output "log_group_ids" {
  value = { for k, v in oci_logging_log_group.this : k => v.id }
}
