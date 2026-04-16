# EFS File System Outputs
output "file_system_ids" {
  description = "Map of file system keys to IDs"
  value       = { for k, v in module.efs : k => v.id }
}

output "file_system_arns" {
  description = "Map of file system keys to ARNs"
  value       = { for k, v in module.efs : k => v.arn }
}

output "file_system_dns_names" {
  description = "Map of file system keys to DNS names"
  value       = { for k, v in module.efs : k => v.dns_name }
}

output "file_system_names" {
  description = "Map of file system keys to names"
  value       = { for k, v in module.efs : k => v.name }
}

output "file_system_size_in_bytes" {
  description = "Map of file system keys to size in bytes"
  value       = { for k, v in module.efs : k => v.size_in_bytes }
}

output "file_system_number_of_mount_targets" {
  description = "Map of file system keys to number of mount targets"
  value       = { for k, v in module.efs : k => v.number_of_mount_targets }
}

# EFS Mount Target Outputs
output "mount_target_ids" {
  description = "Map of mount target keys to IDs"
  value = {
    for k, v in module.efs : k => v.mount_targets
  }
}

output "mount_target_dns_names" {
  description = "Map of mount target keys to DNS names"
  value = {
    for k, v in module.efs : k => {
      for subnet_id, mt in v.mount_targets : subnet_id => mt.dns_name
    }
  }
}

output "mount_target_network_interface_ids" {
  description = "Map of mount target keys to network interface IDs"
  value = {
    for k, v in module.efs : k => {
      for subnet_id, mt in v.mount_targets : subnet_id => mt.network_interface_id
    }
  }
}

output "mount_target_ip_addresses" {
  description = "Map of mount target keys to IP addresses"
  value = {
    for k, v in module.efs : k => {
      for subnet_id, mt in v.mount_targets : subnet_id => mt.ip_address
    }
  }
}

output "mount_target_availability_zones" {
  description = "Map of mount target keys to availability zones"
  value = {
    for k, v in module.efs : k => {
      for subnet_id, mt in v.mount_targets : subnet_id => mt.availability_zone_name
    }
  }
}

# EFS Access Point Outputs
output "access_point_ids" {
  description = "Map of access point keys to IDs"
  value = {
    for k, v in module.efs : k => {
      for ap_key, ap in v.access_points : ap_key => ap.id
    }
  }
}

output "access_point_arns" {
  description = "Map of access point keys to ARNs"
  value = {
    for k, v in module.efs : k => {
      for ap_key, ap in v.access_points : ap_key => ap.arn
    }
  }
}

output "access_point_file_system_arns" {
  description = "Map of access point keys to file system ARNs"
  value = {
    for k, v in module.efs : k => {
      for ap_key, ap in v.access_points : ap_key => ap.file_system_arn
    }
  }
}

# EFS Backup Policy Outputs
output "backup_policy_ids" {
  description = "Map of file system keys to backup policy IDs"
  value       = { for k, v in module.efs : k => v.backup_policy_id if v.backup_policy_id != null }
}

# EFS File System Policy Outputs
output "file_system_policy_ids" {
  description = "Map of file system keys to policy IDs"
  value       = { for k, v in module.efs : k => v.policy_id if v.policy_id != null }
}

# EFS Replication Configuration Outputs
output "replication_configuration_ids" {
  description = "Map of file system keys to replication configuration IDs"
  value       = { for k, v in module.efs : k => v.replication_configuration_id if v.replication_configuration_id != null }
}

output "replication_source_file_system_ids" {
  description = "Map of file system keys to source file system IDs in replication"
  value = {
    for k, v in module.efs : k => v.id
    if try(v.replication_configuration_id, null) != null
  }
}

output "replication_creation_times" {
  description = "Map of file system keys to replication creation times"
  value = {
    for k, v in module.efs : k => v.replication_configuration_creation_time
    if try(v.replication_configuration_creation_time, null) != null
  }
}

# Convenience Outputs
output "region" {
  description = "AWS region where EFS resources are created"
  value       = data.aws_region.current.id
}
