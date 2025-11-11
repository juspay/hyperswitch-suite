resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  version         = var.kubernetes_version

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  ami_type             = var.ami_type
  capacity_type        = var.capacity_type
  disk_size            = var.disk_size
  instance_types       = var.instance_types
  labels               = var.labels
  release_version      = var.release_version
  force_update_version = var.force_update_version

  dynamic "launch_template" {
    for_each = var.launch_template_id != null ? [1] : []
    content {
      id      = var.launch_template_id
      version = var.launch_template_version
    }
  }

  dynamic "remote_access" {
    for_each = var.remote_access_ec2_ssh_key != null ? [1] : []
    content {
      ec2_ssh_key               = var.remote_access_ec2_ssh_key
      source_security_group_ids = var.remote_access_source_sg_ids
    }
  }

  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.node_group_name
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }

  depends_on = [var.node_group_dependencies]
}
