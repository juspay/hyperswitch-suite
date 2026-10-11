locals {
  create_bucket = var.create
  bucket_name   = var.bucket_name != "" ? var.bucket_name : "${var.project_name}-cf-logs-${var.environment}"
  
  tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Purpose     = "cloudfront-logs"
    },
    var.tags
  )
}

data "aws_region" "current" {}

resource "aws_s3_bucket" "logs" {
  count = local.create_bucket ? 1 : 0

  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "logs" {
  count = local.create_bucket && var.versioning_enabled ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.sse_algorithm == "aws:kms"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = local.create_bucket && var.block_public_access ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = local.create_bucket && length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      dynamic "transition" {
        for_each = rule.value.transition_to_ia_days != null ? [rule.value.transition_to_ia_days] : []
        content {
          days          = transition.value
          storage_class = "STANDARD_IA"
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition_to_glacier_days != null ? [rule.value.transition_to_glacier_days] : []
        content {
          days          = transition.value
          storage_class = "GLACIER"
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [rule.value.expiration_days] : []
        content {
          days = expiration.value
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition_ia_days != null ? [rule.value.noncurrent_version_transition_ia_days] : []
        content {
          noncurrent_days = noncurrent_version_transition.value
          storage_class   = "STANDARD_IA"
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition_glacier_days != null ? [rule.value.noncurrent_version_transition_glacier_days] : []
        content {
          noncurrent_days = noncurrent_version_transition.value
          storage_class   = "GLACIER"
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days != null ? [rule.value.noncurrent_version_expiration_days] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.logs]
}

data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket_policy" "logs" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontLogs"
        Effect    = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "AllowCloudFrontAccessLogs"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::127311923021:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs[0].arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_replication_configuration" "logs" {
  count = local.create_bucket && var.enable_replication ? 1 : 0

  role   = var.replication_role_arn
  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "replicate-logs"
    status = "Enabled"

    destination {
      bucket        = var.replication_target_bucket_arn
      storage_class = var.replication_storage_class
    }
  }

  depends_on = [aws_s3_bucket_versioning.logs]
}
