# Data sources
data "aws_region" "current" {}

# EFS File Systems
resource "aws_efs_file_system" "file_systems" {
  for_each = var.file_systems

  # Basic Configuration
  creation_token                  = each.value.creation_token != null ? each.value.creation_token : "${local.name_prefix}-${each.key}"
  performance_mode                = each.value.performance_mode
  throughput_mode                 = each.value.throughput_mode
  provisioned_throughput_in_mibps = each.value.throughput_mode == "provisioned" ? each.value.provisioned_throughput_in_mibps : null

  # Encryption
  encrypted  = each.value.encrypted
  kms_key_id = each.value.kms_key_id

  # Lifecycle Policy
  dynamic "lifecycle_policy" {
    for_each = each.value.lifecycle_policies
    content {
      transition_to_ia                    = lifecycle_policy.value.transition_to_ia
      transition_to_primary_storage_class = lifecycle_policy.value.transition_to_primary_storage_class
      transition_to_archive               = lifecycle_policy.value.transition_to_archive
    }
  }

  # Protection
  dynamic "protection" {
    for_each = each.value.replication_overwrite_protection != null ? [1] : []
    content {
      replication_overwrite = each.value.replication_overwrite_protection
    }
  }

  tags = merge(local.common_tags, {
    Name = each.value.name
  }, each.value.tags)
}

# EFS Backup Policy
resource "aws_efs_backup_policy" "backup_policies" {
  for_each = { for k, v in var.file_systems : k => v if v.enable_backup_policy }

  file_system_id = aws_efs_file_system.file_systems[each.key].id

  backup_policy {
    status = each.value.backup_policy_status
  }
}

# EFS Mount Targets
resource "aws_efs_mount_target" "mount_targets" {
  for_each = merge([
    for fs_key, fs in var.file_systems : {
      for subnet_id in fs.subnet_ids :
      "${fs_key}-${subnet_id}" => {
        file_system_id  = aws_efs_file_system.file_systems[fs_key].id
        subnet_id       = subnet_id
        security_groups = fs.security_group_ids
        ip_address      = try(fs.mount_target_ip_addresses[subnet_id], null)
      }
    }
  ]...)

  file_system_id  = each.value.file_system_id
  subnet_id       = each.value.subnet_id
  security_groups = each.value.security_groups
  ip_address      = each.value.ip_address
}

# EFS Access Points
resource "aws_efs_access_point" "access_points" {
  for_each = merge([
    for fs_key, fs in var.file_systems : {
      for ap_key, ap in fs.access_points :
      "${fs_key}-${ap_key}" => merge(ap, {
        file_system_id = aws_efs_file_system.file_systems[fs_key].id
        fs_key         = fs_key
      })
    }
  ]...)

  file_system_id = each.value.file_system_id

  # POSIX User
  dynamic "posix_user" {
    for_each = each.value.posix_user != null ? [each.value.posix_user] : []
    content {
      gid            = posix_user.value.gid
      uid            = posix_user.value.uid
      secondary_gids = posix_user.value.secondary_gids
    }
  }

  # Root Directory
  dynamic "root_directory" {
    for_each = each.value.root_directory != null ? [each.value.root_directory] : []
    content {
      path = root_directory.value.path

      dynamic "creation_info" {
        for_each = root_directory.value.creation_info != null ? [root_directory.value.creation_info] : []
        content {
          owner_gid   = creation_info.value.owner_gid
          owner_uid   = creation_info.value.owner_uid
          permissions = creation_info.value.permissions
        }
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = each.value.name
  }, each.value.tags)
}

# EFS File System Policy
resource "aws_efs_file_system_policy" "file_system_policies" {
  for_each = { for k, v in var.file_systems : k => v if v.file_system_policy != null }

  file_system_id                     = aws_efs_file_system.file_systems[each.key].id
  bypass_policy_lockout_safety_check = each.value.bypass_policy_lockout_safety_check
  policy                             = each.value.file_system_policy
}

# EFS Replication Configuration
resource "aws_efs_replication_configuration" "replication" {
  for_each = { for k, v in var.file_systems : k => v if v.replication_configuration != null }

  source_file_system_id = aws_efs_file_system.file_systems[each.key].id

  destination {
    region                 = each.value.replication_configuration.destination_region
    file_system_id         = each.value.replication_configuration.destination_file_system_id
    availability_zone_name = each.value.replication_configuration.destination_availability_zone_name
    kms_key_id             = each.value.replication_configuration.destination_kms_key_id
  }
}
