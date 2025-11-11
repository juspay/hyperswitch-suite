locals {
  user_data_final = var.user_data_base64 != null ? var.user_data_base64 : (
    var.user_data != "" ? base64encode(var.user_data) : null
  )
}

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.iam_instance_profile_name
  key_name                    = var.key_name
  monitoring                  = var.monitoring
  tenancy                     = var.tenancy
  user_data_base64            = local.user_data_final
  user_data_replace_on_change = var.user_data_replace_on_change
  source_dest_check           = var.source_dest_check
  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ip

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    iops                  = var.root_volume_iops
    throughput            = var.root_volume_throughput
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_kms_key_id
    delete_on_termination = var.root_volume_delete_on_termination
    tags = merge(
      var.tags,
      {
        Name = "${var.name}-root-volume"
      }
    )
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
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
