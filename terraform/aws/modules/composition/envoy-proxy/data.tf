# =========================================================================
# Data Sources
# =========================================================================

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Reference to existing IAM role (if using existing)
data "aws_iam_role" "existing_envoy_role" {
  count = var.create_iam_role ? 0 : 1
  name  = var.existing_iam_role_name
}

# Regional S3 managed prefix list, for scoping instance egress to the
# S3 gateway VPC endpoint instead of 0.0.0.0/0
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}
