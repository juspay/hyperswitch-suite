data "aws_caller_identity" "current" {}

# Regional S3 managed prefix list, for scoping instance egress to the
# S3 gateway VPC endpoint instead of 0.0.0.0/0
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.region}.s3"
}
