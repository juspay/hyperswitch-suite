# =========================================================================
# IAM - ROLE
# =========================================================================
resource "aws_iam_role" "this" {
  name                  = var.role_name != null ? var.role_name : "${local.name_prefix}-role"
  description           = var.role_description != null ? var.role_description : "IAM role for ${title(var.app_name)} ${title(var.environment)} application"
  path                  = var.role_path
  max_session_duration  = var.max_session_duration
  force_detach_policies = var.force_detach_policies

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # OIDC trust relationships for EKS IRSA
      [
        for cluster_name, statement in local.cluster_oidc_statements : {
          Effect = "Allow"
          Principal = {
            Federated = statement.oidc_arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${statement.oidc_url}:aud" = "sts.amazonaws.com"
              "${statement.oidc_url}:sub" = statement.subjects
            }
          }
        }
      ],
      # Additional AWS principal trust relationships
      local.assume_role_principals_enabled ? [
        {
          Effect = "Allow"
          Principal = {
            AWS = var.assume_role_principals
          }
          Action = "sts:AssumeRole"
        }
      ] : [],
      # Additional custom trust statements
      var.additional_assume_role_statements
    )
  })

  tags = local.common_tags
}

# =========================================================================
# IAM - AWS MANAGED POLICY ATTACHMENTS
# =========================================================================
resource "aws_iam_role_policy_attachment" "aws_managed" {
  for_each = local.aws_managed_policies_enabled ? toset(var.aws_managed_policy_names) : toset([])

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

# =========================================================================
# IAM - CUSTOMER MANAGED POLICY ATTACHMENTS
# =========================================================================
resource "aws_iam_role_policy_attachment" "customer_managed" {
  for_each = local.customer_managed_policies_enabled ? toset(var.customer_managed_policy_arns) : toset([])

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# =========================================================================
# IAM - INLINE POLICIES
# =========================================================================
resource "aws_iam_role_policy" "otel_collector" {
  count = var.create_otel_collector_policy ? 1 : 0

  name = "${local.name_prefix}-otel-collector-policy"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # CloudWatch Logs permissions for sending logs
      var.enable_cloudwatch_logs ? [
        {
          Sid    = "CloudWatchLogs"
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
            "logs:PutRetentionPolicy"
          ]
          Resource = var.cloudwatch_logs_log_group_arn != null ? var.cloudwatch_logs_log_group_arn : "arn:aws:logs:*:*:*"
        }
      ] : [],
      # CloudWatch Metrics permissions for sending metrics
      var.enable_cloudwatch_metrics ? [
        {
          Sid    = "CloudWatchMetrics"
          Effect = "Allow"
          Action = [
            "cloudwatch:PutMetricData",
            "cloudwatch:ListMetrics"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "cloudwatch:namespace" = var.cloudwatch_metrics_namespace
            }
          }
        }
      ] : [],
      # X-Ray permissions for tracing
      var.enable_xray_tracing ? [
        {
          Sid    = "XRayTracing"
          Effect = "Allow"
          Action = [
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords",
            "xray:GetSamplingRules",
            "xray:GetSamplingTargets",
            "xray:GetSamplingStatisticSummaries"
          ]
          Resource = "*"
        }
      ] : [],
      # S3 permissions for storing telemetry data
      var.enable_s3_export ? [
        {
          Sid    = "S3Export"
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Resource = var.s3_export_bucket_arn != null ? [
            var.s3_export_bucket_arn,
            "${var.s3_export_bucket_arn}/*"
          ] : ["arn:aws:s3:::*", "arn:aws:s3:::*/*"]
        }
      ] : [],
      # Kinesis Data Firehose permissions
      var.enable_kinesis_firehose ? [
        {
          Sid    = "KinesisFirehose"
          Effect = "Allow"
          Action = [
            "firehose:PutRecord",
            "firehose:PutRecordBatch"
          ]
          Resource = var.kinesis_firehose_stream_arn != null ? var.kinesis_firehose_stream_arn : "arn:aws:firehose:*:*:*"
        }
      ] : []
    )
  })
}
