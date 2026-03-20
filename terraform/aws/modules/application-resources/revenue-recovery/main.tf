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
# IAM - S3 POLICY
# =========================================================================
resource "aws_iam_policy" "s3_policy" {
  count = local.s3_enabled ? 1 : 0

  name = "${local.name_prefix}-s3-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "${local.s3_bucket_arn}/*",
          local.s3_bucket_arn
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  count = local.s3_enabled ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.s3_policy[0].arn
}

# =========================================================================
# S3 BUCKET (Optional)
# =========================================================================
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  count = local.s3_create ? 1 : 0

  bucket = local.s3_bucket_name

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = try(var.s3.versioning_enabled, false) ? {
    enabled = true
  } : {}

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  lifecycle_rule = try(var.s3.lifecycle_rules, [])

  tags = local.common_tags

  force_destroy = try(var.s3.force_destroy, false)
}

# =========================================================================
# AWS TRANSFER FAMILY - SFTP SERVER (Optional)
# =========================================================================
resource "aws_transfer_server" "sftp" {
  count = local.sftp_enabled ? 1 : 0

  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  endpoint_type          = try(var.sftp.endpoint_type, "PUBLIC")
  security_policy_name   = try(var.sftp.security_policy_name, "TransferSecurityPolicy-2024-01")

  logging_role = aws_iam_role.sftp_logging[0].arn

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sftp"
  })
}

# IAM role for Transfer Family server CloudWatch logging
resource "aws_iam_role" "sftp_logging" {
  count = local.sftp_enabled ? 1 : 0

  name        = "${local.name_prefix}-sftp-logging-role"
  description = "IAM role for AWS Transfer Family SFTP server CloudWatch logging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "sftp_logging" {
  count = local.sftp_enabled ? 1 : 0

  name = "sftp-cloudwatch-logging"
  role = aws_iam_role.sftp_logging[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# SFTP users
resource "aws_transfer_user" "sftp" {
  for_each = local.sftp_enabled ? { for u in try(var.sftp.users, []) : u.username => u } : {}

  server_id      = aws_transfer_server.sftp[0].id
  user_name      = each.value.username
  role           = aws_iam_role.this.arn
  home_directory = try(each.value.home_directory, "/${try(var.s3.bucket_name, local.s3_bucket_name)}")

  home_directory_type = "PATH"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sftp-user-${each.value.username}"
  })
}

# SSH public keys for SFTP users
resource "aws_transfer_ssh_key" "sftp" {
  for_each = local.sftp_enabled ? {
    for u in try(var.sftp.users, []) : u.username => u
    if try(u.public_key, null) != null
  } : {}

  server_id = aws_transfer_server.sftp[0].id
  user_name = aws_transfer_user.sftp[each.key].user_name
  body      = each.value.public_key
}
