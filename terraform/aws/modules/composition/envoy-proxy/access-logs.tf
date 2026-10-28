locals {
  alb_access_logs_enabled        = var.create_lb && var.enable_alb_access_logs
  alb_access_logs_load_balancers = local.alb_access_logs_enabled ? { envoy = module.alb[0].arn } : {}
  alb_access_logs_group_name     = coalesce(var.alb_access_logs_log_group_name, "/aws/vendedlogs/alb/${local.name_prefix}/access")
  alb_access_logs_group_arn      = local.alb_access_logs_enabled ? "arn:${data.aws_partition.alb_access_logs[0].partition}:logs:${data.aws_region.alb_access_logs[0].region}:${data.aws_caller_identity.alb_access_logs[0].account_id}:log-group:${local.alb_access_logs_group_name}" : null
  alb_access_logs_delivery_name  = "alb-${substr(sha256(local.alb_access_logs_group_name), 0, 32)}-access"
  alb_access_logs_kms_key_arn    = local.alb_access_logs_enabled ? (var.alb_access_logs_kms_key_arn != null ? var.alb_access_logs_kms_key_arn : aws_kms_key.alb_access_logs[0].arn) : null
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
  count = local.alb_access_logs_enabled && var.alb_access_logs_kms_key_arn == null ? 1 : 0

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
  retention_in_days = var.alb_access_logs_retention_days
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

