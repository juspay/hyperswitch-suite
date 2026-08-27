output "instance_ids" {
  description = "Map of instance key to its fully qualified ID"
  value       = { for k, v in google_filestore_instance.this : k => v.id }
}

output "instance_ip_addresses" {
  description = "Map of instance key to its list of file-share IP addresses"
  value       = { for k, v in google_filestore_instance.this : k => v.networks[0].ip_addresses }
}

output "backup_ids" {
  description = "Map of instance key to its backup ID, for instances with create_backup = true"
  value       = { for k, v in google_filestore_backup.this : k => v.id }
}
