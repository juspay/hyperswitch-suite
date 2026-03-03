# =============================================================================
# EKS Composition Module - Launch Templates
# =============================================================================

# -----------------------------------------------------------------------------
# Default Launch Template
# Used by node groups that don't specify custom launch_template config
# -----------------------------------------------------------------------------
resource "aws_launch_template" "default" {
  count = local.create_node_groups ? 1 : 0

  name_prefix = "${var.environment}-${var.project_name}-nodes-"
  description = "EKS nodes default launch template"

  # Use provided default AMI ID
  image_id = var.default_ami_id

  # SSH Key (if configured)
  key_name = local.ssh_key_name

  # Security groups from EKS cluster
  vpc_security_group_ids = [
    module.eks.cluster_security_group_id,
    module.eks.node_security_group_id
  ]

  # Block device configuration (dynamic based on default_block_device_mappings)
  dynamic "block_device_mappings" {
    for_each = length(var.default_block_device_mappings) > 0 ? var.default_block_device_mappings : [
      {
        device_name           = "/dev/xvda"
        volume_size           = 20
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = true
        kms_key_id            = null
        iops                  = null
        throughput            = null
      }
    ]
    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = block_device_mappings.value.volume_size
        volume_type           = block_device_mappings.value.volume_type
        delete_on_termination = block_device_mappings.value.delete_on_termination
        encrypted             = block_device_mappings.value.encrypted
        kms_key_id            = try(block_device_mappings.value.kms_key_id, null)
        iops                  = try(block_device_mappings.value.iops, null)
        throughput            = try(block_device_mappings.value.throughput, null)
      }
    }
  }

  # Metadata options (IMDSv2 by default, configurable)
  metadata_options {
    http_endpoint               = local.default_metadata.http_endpoint
    http_tokens                 = local.default_metadata.http_tokens
    http_put_response_hop_limit = local.default_metadata.http_put_response_hop_limit
    instance_metadata_tags      = local.default_metadata.instance_metadata_tags
  }

  # User data with cluster details for AL2023 nodeadm
  user_data = base64encode(templatefile(
    coalesce(var.custom_userdata_template_path, "${path.module}/templates/bootstrap-userdata.tpl"),
    {
      cluster_name     = "${var.environment}-${var.project_name}-cluster-${var.cluster_name_version}"
      cluster_endpoint = module.eks.cluster_endpoint
      cluster_ca       = module.eks.cluster_certificate_authority_data
      cluster_cidr     = module.eks.cluster_service_cidr
    }
  ))

  # Tag specifications
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.environment}-${var.project_name}-node"
    })
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [module.eks]
}

# -----------------------------------------------------------------------------
# Custom Launch Templates per Node Group
# Created when:
#   - create_security_group = true (SG will be attached)
#   - launch_template.ami_id is specified
#   - launch_template.additional_security_group_ids is specified
#   - launch_template.block_device_mappings is specified
#   - launch_template.metadata_options is specified
# -----------------------------------------------------------------------------
resource "aws_launch_template" "custom_node_group" {
  for_each = local.node_groups_needing_custom_lt

  name_prefix = "${var.environment}-${var.project_name}-${each.key}-"
  description = "Custom launch template for ${each.key} node group"

  # AMI: custom if specified, otherwise use default
  image_id = coalesce(
    try(each.value.launch_template.ami_id, null),
    var.default_ami_id
  )

  # SSH Key (if configured)
  key_name = local.ssh_key_name

  # Security groups:
  # 1. Node group's created SG (if create_security_group = true)
  # 2. Additional SGs from launch_template config
  # 3. EKS cluster security groups
  vpc_security_group_ids = concat(
    # Include created security group if create_security_group = true
    try(each.value.create_security_group, false) ? [aws_security_group.node_group[each.key].id] : [],
    # Include additional security groups from launch_template config
    try(each.value.launch_template.additional_security_group_ids, []),
    [
      module.eks.cluster_security_group_id,
      module.eks.node_security_group_id
    ]
  )

  # Block device configuration (custom or default)
  dynamic "block_device_mappings" {
    for_each = (
      try(each.value.launch_template.block_device_mappings, null) != null
      ) ? each.value.launch_template.block_device_mappings : (
      length(var.default_block_device_mappings) > 0 ? var.default_block_device_mappings : [
        {
          device_name           = "/dev/xvda"
          volume_size           = 20
          volume_type           = "gp3"
          delete_on_termination = true
          encrypted             = true
          kms_key_id            = null
          iops                  = null
          throughput            = null
        }
      ]
    )
    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = block_device_mappings.value.volume_size
        volume_type           = block_device_mappings.value.volume_type
        delete_on_termination = block_device_mappings.value.delete_on_termination
        encrypted             = block_device_mappings.value.encrypted
        kms_key_id            = try(block_device_mappings.value.kms_key_id, null)
        iops                  = try(block_device_mappings.value.iops, null)
        throughput            = try(block_device_mappings.value.throughput, null)
      }
    }
  }

  # Metadata options (custom or default)
  metadata_options {
    http_endpoint               = try(each.value.launch_template.metadata_options.http_endpoint, local.default_metadata.http_endpoint)
    http_tokens                 = try(each.value.launch_template.metadata_options.http_tokens, local.default_metadata.http_tokens)
    http_put_response_hop_limit = try(each.value.launch_template.metadata_options.http_put_response_hop_limit, local.default_metadata.http_put_response_hop_limit)
    instance_metadata_tags      = try(each.value.launch_template.metadata_options.instance_metadata_tags, local.default_metadata.instance_metadata_tags)
  }

  # User data with cluster details for AL2023 nodeadm
  user_data = base64encode(templatefile(
    coalesce(var.custom_userdata_template_path, "${path.module}/templates/bootstrap-userdata.tpl"),
    {
      cluster_name     = "${var.environment}-${var.project_name}-cluster-${var.cluster_name_version}"
      cluster_endpoint = module.eks.cluster_endpoint
      cluster_ca       = module.eks.cluster_certificate_authority_data
      cluster_cidr     = module.eks.cluster_service_cidr
    }
  ))

  # Tag specifications
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.environment}-${var.project_name}-${each.key}"
    })
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [module.eks]
}
