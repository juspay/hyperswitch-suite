locals {
  cloudwatch_logging = var.alb_access_logs_cloudwatch
  s3_logging         = var.alb_access_logs_s3
}

locals {
  alb_access_logs_enabled        = var.create_lb && local.cloudwatch_logging.enabled
  alb_access_logs_load_balancers = local.alb_access_logs_enabled ? { envoy = module.alb[0].arn } : {}
  alb_access_logs_group_name     = coalesce(local.cloudwatch_logging.log_group_name, "/aws/vendedlogs/alb/${local.name_prefix}/access")
  alb_access_logs_group_arn      = local.alb_access_logs_enabled ? "arn:${data.aws_partition.alb_access_logs[0].partition}:logs:${data.aws_region.alb_access_logs[0].region}:${data.aws_caller_identity.alb_access_logs[0].account_id}:log-group:${local.alb_access_logs_group_name}" : null
  alb_access_logs_delivery_name  = "alb-${substr(sha256(local.alb_access_logs_group_name), 0, 32)}-access"
  alb_access_logs_kms_key_arn    = local.alb_access_logs_enabled ? (local.cloudwatch_logging.kms_key_arn != null ? local.cloudwatch_logging.kms_key_arn : aws_kms_key.alb_access_logs[0].arn) : null
}

data "aws_caller_identity" "alb_access_logs" {
  count = local.alb_access_logs_enabled ? 1 : 0
}
data "aws_region" "alb_access_logs" {
  count = local.alb_access_logs_enabled ? 1 : 0
}
data "aws_partition" "alb_access_logs" {
  count = local.alb_access_logs_enabled ? 1 : 0
}

resource "aws_kms_key" "alb_access_logs" {
  count = local.alb_access_logs_enabled && local.cloudwatch_logging.kms_key_arn == null ? 1 : 0

  description             = "Encrypt ALB access logs for ${local.alb_access_logs_group_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EnableAccountPermissions"
      Effect    = "Allow"
      Principal = { AWS = "arn:${data.aws_partition.alb_access_logs[0].partition}:iam::${data.aws_caller_identity.alb_access_logs[0].account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
      }, {
      Sid       = "AllowCloudWatchLogs"
      Effect    = "Allow"
      Principal = { Service = "logs.${data.aws_region.alb_access_logs[0].region}.${data.aws_partition.alb_access_logs[0].dns_suffix}" }
      Action    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
      Resource  = "*"
      Condition = { ArnEquals = { "kms:EncryptionContext:aws:logs:arn" = local.alb_access_logs_group_arn } }
    }]
  })
  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "alb_access_logs" {
  count = local.alb_access_logs_enabled ? 1 : 0

  name              = local.alb_access_logs_group_name
  retention_in_days = local.cloudwatch_logging.retention_days
  kms_key_id        = local.alb_access_logs_kms_key_arn
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_resource_policy" "alb_access_logs" {
  count = local.alb_access_logs_enabled ? 1 : 0

  resource_arn = aws_cloudwatch_log_group.alb_access_logs[0].arn
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowALBLogDelivery"
      Effect    = "Allow"
      Principal = { Service = "delivery.logs.amazonaws.com" }
      Action    = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource  = "${aws_cloudwatch_log_group.alb_access_logs[0].arn}:log-stream:*"
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.alb_access_logs[0].account_id }
        ArnLike = {
          "aws:SourceArn" = "arn:${data.aws_partition.alb_access_logs[0].partition}:logs:${data.aws_region.alb_access_logs[0].region}:${data.aws_caller_identity.alb_access_logs[0].account_id}:*"
        }
      }
    }]
  })
}

resource "aws_cloudwatch_log_delivery_source" "alb_access_logs" {
  for_each = local.alb_access_logs_load_balancers

  name         = "alb-${substr(sha256(each.value), 0, 32)}-access"
  log_type     = "ALB_ACCESS_LOGS"
  resource_arn = each.value
  tags         = local.common_tags
}

resource "aws_cloudwatch_log_delivery_destination" "alb_access_logs" {
  count = local.alb_access_logs_enabled ? 1 : 0

  name          = local.alb_access_logs_delivery_name
  output_format = "json"
  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.alb_access_logs[0].arn
  }
  tags = local.common_tags
}

resource "aws_cloudwatch_log_delivery" "alb_access_logs" {
  for_each = local.alb_access_logs_load_balancers

  delivery_source_name     = aws_cloudwatch_log_delivery_source.alb_access_logs[each.key].name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.alb_access_logs[0].arn
  tags                     = local.common_tags
  depends_on               = [aws_cloudwatch_log_resource_policy.alb_access_logs]
}

# =========================================================================
# ALB S3 Access Logging
# =========================================================================

data "aws_region" "alb_access_logs_s3" {
  count = local.s3_logging.create_bucket ? 1 : 0
}

data "aws_caller_identity" "alb_access_logs_s3" {
  count = local.s3_logging.create_bucket ? 1 : 0
}

data "aws_partition" "alb_access_logs_s3" {
  count = local.s3_logging.create_bucket ? 1 : 0
}

locals {
  alb_access_logs_s3_prefix_path = local.s3_logging.prefix == "" ? "" : "${local.s3_logging.prefix}/"
}

module "alb_access_logs_s3" {
  count   = local.s3_logging.create_bucket ? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = coalesce(local.s3_logging.bucket_name, "${var.environment}-${var.project_name}-envoy-alb-logs-${data.aws_caller_identity.alb_access_logs_s3[0].account_id}-${data.aws_region.alb_access_logs_s3[0].region}")
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
      Resource  = "arn:${data.aws_partition.alb_access_logs_s3[0].partition}:s3:::${coalesce(local.s3_logging.bucket_name, "${var.environment}-${var.project_name}-envoy-alb-logs-${data.aws_caller_identity.alb_access_logs_s3[0].account_id}-${data.aws_region.alb_access_logs_s3[0].region}")}/${local.alb_access_logs_s3_prefix_path}AWSLogs/${data.aws_caller_identity.alb_access_logs_s3[0].account_id}/*"
    }]
  })

  tags = local.common_tags
}
