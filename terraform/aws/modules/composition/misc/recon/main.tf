# =========================================================================
# DATA SOURCES
# =========================================================================
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# =========================================================================
# IAM - ROLE
# =========================================================================
resource "aws_iam_role" "recon_role" {
  name        = "${local.name_prefix}-role"
  description = "IAM role for Hyperswitch Sandbox Recon Service"
  path        = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider_id}:aud" = "sts.amazonaws.com"
            "${var.oidc_provider_id}:sub" = var.service_accounts
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# =========================================================================
# S3 BUCKET
# =========================================================================
module "recon_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  bucket        = var.s3_bucket_name != null ? var.s3_bucket_name : "${local.name_prefix}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.id}"
  force_destroy = var.s3_force_destroy

  # Versioning
  versioning = {
    enabled = var.enable_s3_versioning
  }

  # Security best practices - Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Server-side encryption with KMS
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  tags = local.common_tags
}

# =========================================================================
# IAM - CUSTOM POLICIES
# =========================================================================
# KMS Policy
resource "aws_iam_policy" "recon_kms" {
  name = "${local.name_prefix}-kms-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKMSEncryptDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt"
        ]
        Resource = [var.kms_key_arn]
      }
    ]
  })

  tags = local.common_tags
}

# S3 Policy
resource "aws_iam_policy" "recon_s3" {
  name = "${local.name_prefix}-s3-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3ReadWrite"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          module.recon_bucket.s3_bucket_arn,
          "${module.recon_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

# =========================================================================
# IAM - POLICY ATTACHMENTS
# =========================================================================
# Custom Policy Attachments
resource "aws_iam_role_policy_attachment" "recon_kms" {
  role       = aws_iam_role.recon_role.name
  policy_arn = aws_iam_policy.recon_kms.arn
}

resource "aws_iam_role_policy_attachment" "recon_s3" {
  role       = aws_iam_role.recon_role.name
  policy_arn = aws_iam_policy.recon_s3.arn
}



