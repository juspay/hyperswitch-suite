# =========================================================================
# Data Sources
# =========================================================================

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# =========================================================================
# Blue-Green Deployment Data Sources
# =========================================================================

# Find existing blue ASG for blue-green deployments
# This assumes the blue ASG is already tagged appropriately
data "aws_autoscaling_groups" "groups_blue" {

  # Filter by common tags to find ASGs from this module
  dynamic "filter" {
    for_each = local.common_tags

    content {
      name   = "tag:${filter.key}"
      values = [filter.value]
    }
  }

  # Filter specifically for blue deployment
  filter {
    name   = "tag:Deployment"
    values = ["blue"]
  }
}

data "aws_autoscaling_groups" "groups_green" {

  # Filter by common tags to find ASGs from this module
  dynamic "filter" {
    for_each = local.common_tags

    content {
      name   = "tag:${filter.key}"
      values = [filter.value]
    }
  }

  # Filter specifically for blue deployment
  filter {
    name   = "tag:Deployment"
    values = ["green"]
  }
}

# Get details of the blue ASG
data "aws_autoscaling_group" "asg_blue" {
  count = length(data.aws_autoscaling_groups.groups_blue.names) > 0 ? 1 : 0
  name  = data.aws_autoscaling_groups.groups_blue.names[0]
}

# Get details of the green ASG
data "aws_autoscaling_group" "asg_green" {
  count = length(data.aws_autoscaling_groups.groups_green.names) > 0 ? 1 : 0
  name  = data.aws_autoscaling_groups.groups_green.names[0]
}

# Reference to existing IAM role (if using existing)
data "aws_iam_role" "existing_envoy_role" {
  count = var.create_iam_role ? 0 : 1
  name  = var.existing_iam_role_name
}
