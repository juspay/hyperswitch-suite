output "file_system_ids" {
  value = { for k, v in oci_file_storage_file_system.this : k => v.id }
}

output "mount_target_ids" {
  value = { for k, v in oci_file_storage_mount_target.this : k => v.id }
}

output "mount_target_private_ips" {
  value = { for k, v in oci_file_storage_mount_target.this : k => v.private_ip_ids }
}
