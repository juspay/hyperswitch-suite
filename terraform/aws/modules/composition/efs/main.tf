# Data sources
data "aws_region" "current" {}

# EFS File Systems using official Terraform AWS module
module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 1.6"

  for_each = var.file_systems

  # Basic Configuration
  name           = each.value.name
  creation_token = each.value.creation_token != null ? each.value.creation_token : "${local.name_prefix}-${each.key}"

  # Performance Configuration
  performance_mode                = each.value.performance_mode
  throughput_mode                 = each.value.throughput_mode
  provisioned_throughput_in_mibps = each.value.throughput_mode == "provisioned" ? each.value.provisioned_throughput_in_mibps : null

  # Encryption
  encrypted   = each.value.encrypted
  kms_key_arn = each.value.kms_key_id

  # Lifecycle Policies
  lifecycle_policy = each.value.lifecycle_policies

  # Protection
  protection = each.value.replication_overwrite_protection != null ? {
    replication_overwrite = each.value.replication_overwrite_protection
  } : {}

  # Backup Policy
  create_backup_policy = each.value.enable_backup_policy
  enable_backup_policy = each.value.enable_backup_policy && each.value.backup_policy_status == "ENABLED"

  # Mount Targets with Security Groups
  mount_targets = {
    for subnet_id in each.value.subnet_ids :
    subnet_id => merge(
      {
        subnet_id = subnet_id
      },
      # Only include security_groups if user provides existing SGs
      length(each.value.security_group_ids) > 0 ? {
        security_groups = each.value.security_group_ids
      } : {}
    )
  }

  # Security Group Configuration
  # Create a dedicated EFS security group if user doesn't provide existing ones
  create_security_group      = length(each.value.security_group_ids) == 0
  security_group_name        = length(each.value.security_group_ids) == 0 ? "${each.value.name}-sg" : null
  security_group_description = length(each.value.security_group_ids) == 0 ? "Security group for ${each.value.name} EFS" : null
  security_group_vpc_id      = length(each.value.security_group_ids) == 0 && each.value.vpc_id != null ? each.value.vpc_id : null

  # Configure security group rules only when creating a new SG
  # Both branches must return the same object structure for type consistency
  security_group_rules = length(each.value.security_group_ids) == 0 ? merge(
    # Ingress rules from allowed security groups (e.g., EKS nodes)
    {
      for idx, sg_id in each.value.allowed_security_group_ids :
      "ingress_nfs_from_sg_${idx}" => {
        type                     = "ingress"
        from_port                = 2049
        to_port                  = 2049
        protocol                 = "tcp"
        source_security_group_id = sg_id
        description              = "NFS from security group ${sg_id}"
      }
    },
    # Ingress rules from allowed CIDR blocks (if any)
    length(each.value.allowed_cidr_blocks) > 0 ? {
      ingress_nfs_from_cidr = {
        type        = "ingress"
        from_port   = 2049
        to_port     = 2049
        protocol    = "tcp"
        cidr_blocks = each.value.allowed_cidr_blocks
        description = "NFS from allowed CIDR blocks"
      }
    } : {},
    # Egress rule (allow all outbound)
    {
      egress_all = {
        type        = "egress"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
      }
    }
    ) : {
    # When using existing security groups, must match the structure above
    # Include egress_all to maintain type consistency (won't be used)
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Placeholder - not used when existing SGs provided"
    }
  }

  # Access Points
  access_points = {
    for ap_key, ap in each.value.access_points :
    ap_key => merge(
      {
        name = ap.name
        tags = ap.tags
      },
      ap.posix_user != null ? {
        posix_user = {
          gid            = ap.posix_user.gid
          uid            = ap.posix_user.uid
          secondary_gids = try(ap.posix_user.secondary_gids, [])
        }
      } : {},
      ap.root_directory != null ? {
        root_directory = merge(
          {
            path = try(ap.root_directory.path, "/")
          },
          ap.root_directory.creation_info != null ? {
            creation_info = {
              owner_gid   = ap.root_directory.creation_info.owner_gid
              owner_uid   = ap.root_directory.creation_info.owner_uid
              permissions = ap.root_directory.creation_info.permissions
            }
          } : {}
        )
      } : {}
    )
  }

  # File System Policy
  attach_policy                      = each.value.file_system_policy != null
  source_policy_documents            = each.value.file_system_policy != null ? [each.value.file_system_policy] : []
  bypass_policy_lockout_safety_check = each.value.bypass_policy_lockout_safety_check

  # Replication Configuration
  create_replication_configuration = each.value.replication_configuration != null
  replication_configuration_destination = each.value.replication_configuration != null ? {
    region                 = try(each.value.replication_configuration.destination_region, null)
    file_system_id         = try(each.value.replication_configuration.destination_file_system_id, null)
    availability_zone_name = try(each.value.replication_configuration.destination_availability_zone_name, null)
    kms_key_id             = try(each.value.replication_configuration.destination_kms_key_id, null)
  } : {}

  tags = merge(local.common_tags, each.value.tags)
}
