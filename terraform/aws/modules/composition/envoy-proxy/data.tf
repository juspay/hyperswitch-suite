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
data "aws_autoscaling_groups" "groups" {
  count = var.blue_green_rollout != null ? 1 : 0

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

# Get details of the blue ASG
data "aws_autoscaling_group" "asg_blue" {
  count = var.blue_green_rollout != null && length(data.aws_autoscaling_groups.groups[0].names) > 0 ? 1 : 0
  name  = data.aws_autoscaling_groups.groups[0].names[0]
}

# Reference to existing IAM role (if using existing)
data "aws_iam_role" "existing_envoy_role" {
  count = var.create_iam_role ? 0 : 1
  name  = var.existing_iam_role_name
}

# =========================================================================
# Validation Data Sources
# =========================================================================

# Validate that blue ASG exists when blue-green is enabled
resource "null_resource" "validate_blue_asg" {
  count = var.blue_green_rollout != null ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(try(data.aws_autoscaling_groups.groups[0].names, [])) > 0
      error_message = "Blue-green rollout enabled but no existing blue ASG found. Ensure the blue ASG exists and is properly tagged with Deployment=blue and matching common tags."
    }
  }
}
