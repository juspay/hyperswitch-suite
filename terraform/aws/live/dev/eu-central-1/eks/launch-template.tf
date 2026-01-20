# VPC CIDR data source for NodeConfig
data "aws_vpc" "cluster_vpc" {
  id = var.vpc_id
}


# Launch Template with Dynamic Bootstrap for AL2023 Nodes
# Note: AMI and instance type are configured per node group
# Custom security group defined here, EKS security groups auto-attached by module
resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${var.environment}-${var.project_name}-nodes-"
  description = "EKS nodes with dynamic bootstrap (default template)"

  image_id = "ami-0e3c92d48f8c1d312" # Amazon Linux 2023 EKS Optimized AMI
  
  # SSH key for remote access
  key_name = "pipeline-test"
  
  # Security groups: custom node SG + EKS-managed cluster and node SGs
  vpc_security_group_ids = [
    module.eks.cluster_security_group_id,
    module.eks.node_security_group_id
  ]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  # Dynamic user data - cluster details fetched at runtime by bootstrap script
  user_data = base64encode(templatefile("${path.module}/templates/bootstrap-userdata.sh", {
    cluster_name = "${var.environment}-${var.project_name}-cluster-${var.cluster_name_version}"
  }))

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

# Per-node-group custom launch templates
# Created when node group has custom_launch_template_config defined
resource "aws_launch_template" "custom_node_group" {
  for_each = {
    for k, v in var.node_groups : k => v
    if lookup(v, "custom_launch_template_config", null) != null
  }

  name_prefix = "${var.environment}-${var.project_name}-${each.key}-"
  description = "Custom launch template for ${each.key}"

  # Use custom AMI if specified, otherwise use default
  image_id = lookup(each.value.custom_launch_template_config, "ami_id", "ami-0e3c92d48f8c1d312")
  
  # SSH key for remote access
  key_name = lookup(each.value.custom_launch_template_config, "key_name", "pipeline-test")
  
  # Custom security groups if specified, otherwise use default EKS security groups
  vpc_security_group_ids = concat(
    lookup(each.value.custom_launch_template_config, "additional_security_group_ids", []),
    [
      module.eks.cluster_security_group_id,
      module.eks.node_security_group_id
    ]
  )

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = lookup(each.value.custom_launch_template_config, "disk_size", 20)
      volume_type           = lookup(each.value.custom_launch_template_config, "disk_type", "gp3")
      delete_on_termination = true
      encrypted             = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  user_data = base64encode(templatefile("${path.module}/templates/bootstrap-userdata.sh", {
    cluster_name = "${var.environment}-${var.project_name}-cluster-${var.cluster_name_version}"
  }))

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
