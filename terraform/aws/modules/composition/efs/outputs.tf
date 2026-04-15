# EFS File System Outputs
output "file_system_ids" {
  description = "Map of file system keys to IDs"
  value       = { for k, v in aws_efs_file_system.file_systems : k => v.id }
}

output "file_system_arns" {
  description = "Map of file system keys to ARNs"
  value       = { for k, v in aws_efs_file_system.file_systems : k => v.arn }
}

output "file_system_dns_names" {
  description = "Map of file system keys to DNS names"
  value       = { for k, v in aws_efs_file_system.file_systems : k => v.dns_name }
}

output "file_system_names" {
  description = "Map of file system keys to names"
  value       = { for k, v in aws_efs_file_system.file_systems : k => v.tags["Name"] }
}

output "file_system_size_in_bytes" {
  description = "Map of file system keys to size in bytes"
  value       = { for k, v in aws_efs_file_system.file_systems : k => v.size_in_bytes }
}

output "file_system_number_of_mount_targets" {
  description = "Map of file system keys to number of mount targets"
  value       = { for k, v in aws_efs_file_system.file_systems : k => v.number_of_mount_targets }
}

# EFS Mount Target Outputs
output "mount_target_ids" {
  description = "Map of mount target keys to IDs"
  value       = { for k, v in aws_efs_mount_target.mount_targets : k => v.id }
}

output "mount_target_dns_names" {
  description = "Map of mount target keys to DNS names"
  value       = { for k, v in aws_efs_mount_target.mount_targets : k => v.dns_name }
}

output "mount_target_network_interface_ids" {
  description = "Map of mount target keys to network interface IDs"
  value       = { for k, v in aws_efs_mount_target.mount_targets : k => v.network_interface_id }
}

output "mount_target_ip_addresses" {
  description = "Map of mount target keys to IP addresses"
  value       = { for k, v in aws_efs_mount_target.mount_targets : k => v.ip_address }
}

output "mount_target_availability_zones" {
  description = "Map of mount target keys to availability zones"
  value       = { for k, v in aws_efs_mount_target.mount_targets : k => v.availability_zone_name }
}

# EFS Access Point Outputs
output "access_point_ids" {
  description = "Map of access point keys to IDs"
  value       = { for k, v in aws_efs_access_point.access_points : k => v.id }
}

output "access_point_arns" {
  description = "Map of access point keys to ARNs"
  value       = { for k, v in aws_efs_access_point.access_points : k => v.arn }
}

output "access_point_file_system_arns" {
  description = "Map of access point keys to file system ARNs"
  value       = { for k, v in aws_efs_access_point.access_points : k => v.file_system_arn }
}

# EFS Backup Policy Outputs
output "backup_policy_ids" {
  description = "Map of file system keys to backup policy IDs"
  value       = { for k, v in aws_efs_backup_policy.backup_policies : k => v.id }
}

# EFS File System Policy Outputs
output "file_system_policy_ids" {
  description = "Map of file system keys to policy IDs"
  value       = { for k, v in aws_efs_file_system_policy.file_system_policies : k => v.id }
}

# EFS Replication Configuration Outputs
output "replication_configuration_ids" {
  description = "Map of file system keys to replication configuration IDs"
  value       = { for k, v in aws_efs_replication_configuration.replication : k => v.id }
}

output "replication_source_file_system_ids" {
  description = "Map of file system keys to source file system IDs in replication"
  value       = { for k, v in aws_efs_replication_configuration.replication : k => v.source_file_system_id }
}

output "replication_creation_times" {
  description = "Map of file system keys to replication creation times"
  value       = { for k, v in aws_efs_replication_configuration.replication : k => v.creation_time }
}

# Convenience Outputs
output "region" {
  description = "AWS region where EFS resources are created"
  value       = data.aws_region.current.name
}
