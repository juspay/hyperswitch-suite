data "aws_region" "alb_access_logs_s3" {
  count = var.create_alb_access_logs_s3_bucket ? 1 : 0
}

data "aws_caller_identity" "alb_access_logs_s3" {
  count = var.create_alb_access_logs_s3_bucket ? 1 : 0
}

data "aws_partition" "alb_access_logs_s3" {
  count = var.create_alb_access_logs_s3_bucket ? 1 : 0
}

locals {
  alb_access_logs_s3_prefix_path = var.alb_access_logs_s3_prefix == "" ? "" : "${var.alb_access_logs_s3_prefix}/"
}

module "alb_access_logs_s3" {
  count   = var.create_alb_access_logs_s3_bucket ? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = coalesce(var.alb_access_logs_s3_bucket_name, "${var.environment}-${var.project_name}-alb-logs-${data.aws_caller_identity.alb_access_logs_s3[0].account_id}-${data.aws_region.alb_access_logs_s3[0].region}")
  force_destroy = false

  block_public_acls                     = true
  block_public_policy                   = true
  ignore_public_acls                    = true
  restrict_public_buckets               = true
  control_object_ownership              = true
  object_ownership                      = "BucketOwnerEnforced"
  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = { sse_algorithm = "AES256" }
    }
  }

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowALBLogDelivery"
      Effect    = "Allow"
      Principal = { Service = "logdelivery.elasticloadbalancing.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "arn:${data.aws_partition.alb_access_logs_s3[0].partition}:s3:::${coalesce(var.alb_access_logs_s3_bucket_name, "${var.environment}-${var.project_name}-alb-logs-${data.aws_caller_identity.alb_access_logs_s3[0].account_id}-${data.aws_region.alb_access_logs_s3[0].region}")}/${local.alb_access_logs_s3_prefix_path}AWSLogs/${data.aws_caller_identity.alb_access_logs_s3[0].account_id}/*"
    }]
  })

  tags = local.common_tags
}
