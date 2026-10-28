locals {
  create_flow_logs_log_group = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" && var.flow_logs_destination_arn == ""
  create_flow_logs_kms_key   = local.create_flow_logs_log_group && var.flow_logs_kms_key_arn == null
  create_flow_logs_role      = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" && var.flow_logs_iam_role_arn == ""
  flow_logs_destination_arn  = local.create_flow_logs_log_group ? aws_cloudwatch_log_group.flow_logs[0].arn : var.flow_logs_destination_arn
  flow_logs_kms_key_arn      = local.create_flow_logs_log_group ? (local.create_flow_logs_kms_key ? aws_kms_key.flow_logs[0].arn : var.flow_logs_kms_key_arn) : null
  flow_logs_iam_role_arn     = var.flow_logs_destination_type == "cloud-watch-logs" ? (local.create_flow_logs_role ? aws_iam_role.flow_logs[0].arn : var.flow_logs_iam_role_arn) : null
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = local.create_flow_logs_log_group ? 1 : 0

  name              = "/aws/vpc/${var.vpc_name}/flow-logs"
  retention_in_days = var.flow_logs_retention_in_days
  kms_key_id        = local.flow_logs_kms_key_arn
  tags              = var.tags
}

data "aws_caller_identity" "flow_logs" {
  count = local.create_flow_logs_role || local.create_flow_logs_kms_key ? 1 : 0
}

data "aws_partition" "flow_logs" {
  count = local.create_flow_logs_role || local.create_flow_logs_kms_key ? 1 : 0
}

resource "aws_iam_role" "flow_logs" {
  count = local.create_flow_logs_role ? 1 : 0

  name_prefix = "vpc-flow-logs-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.flow_logs[0].account_id }
        ArnLike = {
          "aws:SourceArn" = "arn:${data.aws_partition.flow_logs[0].partition}:ec2:${var.region}:${data.aws_caller_identity.flow_logs[0].account_id}:vpc-flow-log/*"
        }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = local.create_flow_logs_role ? 1 : 0

  name = "publish-vpc-flow-logs"
  role = aws_iam_role.flow_logs[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([{
      Effect = "Allow"
      Action = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
      Resource = [
        trimsuffix(local.flow_logs_destination_arn, ":*"),
        "${trimsuffix(local.flow_logs_destination_arn, ":*")}:*"
      ]
      }, {
      Effect   = "Allow"
      Action   = ["logs:DescribeLogGroups"]
      Resource = "*"
      }], local.flow_logs_kms_key_arn == null ? [] : [{
      Effect   = "Allow"
      Action   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
      Resource = local.flow_logs_kms_key_arn
      Condition = {
        StringEquals = { "kms:ViaService" = "logs.${var.region}.${data.aws_partition.flow_logs[0].dns_suffix}" }
      }
    }])
  })
}

resource "aws_kms_key" "flow_logs" {
  count = local.create_flow_logs_kms_key ? 1 : 0

  description             = "Encrypt VPC flow logs for ${var.vpc_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EnableAccountPermissions"
      Effect    = "Allow"
      Principal = { AWS = "arn:${data.aws_partition.flow_logs[0].partition}:iam::${data.aws_caller_identity.flow_logs[0].account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
      }, {
      Sid       = "AllowCloudWatchLogs"
      Effect    = "Allow"
      Principal = { Service = "logs.${var.region}.${data.aws_partition.flow_logs[0].dns_suffix}" }
      Action    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
      Resource  = "*"
      Condition = {
        ArnEquals = {
          "kms:EncryptionContext:aws:logs:arn" = "arn:${data.aws_partition.flow_logs[0].partition}:logs:${var.region}:${data.aws_caller_identity.flow_logs[0].account_id}:log-group:/aws/vpc/${var.vpc_name}/flow-logs"
        }
      }
    }]
  })
  tags = var.tags
}
