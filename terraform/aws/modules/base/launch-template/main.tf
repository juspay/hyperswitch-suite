locals {
  # Use provided base64 encoded user data or encode the provided user data
  user_data_final = var.user_data_base64 != null ? var.user_data_base64 : (
    var.user_data != "" ? base64encode(var.user_data) : null
  )
}

resource "aws_launch_template" "this" {
  name_prefix            = "${var.name}-"
  description            = var.description
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids
  ebs_optimized          = var.ebs_optimized
  user_data              = local.user_data_final
  update_default_version = var.update_default_version

  # IAM instance profile
  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != null || var.iam_instance_profile_arn != null ? [1] : []
    content {
      name = var.iam_instance_profile_name
      arn  = var.iam_instance_profile_arn
    }
  }

  # Monitoring
  monitoring {
    enabled = var.enable_monitoring
  }

  # Metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.metadata_options.instance_metadata_tags
  }

  # Block device mappings
  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name

      dynamic "ebs" {
        for_each = block_device_mappings.value.ebs != null ? [block_device_mappings.value.ebs] : []
        content {
          volume_size           = ebs.value.volume_size
          volume_type           = ebs.value.volume_type
          iops                  = ebs.value.iops
          throughput            = ebs.value.throughput
          delete_on_termination = ebs.value.delete_on_termination
          encrypted             = ebs.value.encrypted
          kms_key_id            = ebs.value.kms_key_id
        }
      }
    }
  }

  # Tag specifications
  dynamic "tag_specifications" {
    for_each = var.tag_specifications
    content {
      resource_type = tag_specifications.value.resource_type
      tags          = tag_specifications.value.tags
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
