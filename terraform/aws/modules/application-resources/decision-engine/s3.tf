# =========================================================================
# S3 BUCKET - Decision Engine Storage
# =========================================================================

locals {
  s3_bucket_name = try(var.s3_bucket.bucket_name, null) != null ? var.s3_bucket.bucket_name : "${local.name_prefix}-storage"
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  count = local.s3_bucket_create ? 1 : 0

  bucket        = local.s3_bucket_name
  force_destroy = try(var.s3_bucket.force_destroy, false)

  # Versioning
  versioning = {
    enabled = try(var.s3_bucket.versioning_enabled, true)
  }

  # Security best practices - Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Server-side encryption with S3-managed keys
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  # Lifecycle rules
  lifecycle_rule = try(length(var.s3_bucket.lifecycle_rules) > 0, false) ? [
    for rule in var.s3_bucket.lifecycle_rules : {
      id     = rule.id
      status = rule.enabled ? "Enabled" : "Disabled"

      filter = {
        prefix = try(rule.prefix, "")
      }

      expiration = rule.expiration_days != null ? {
        days = rule.expiration_days
      } : {}

      noncurrent_version_expiration = rule.noncurrent_version_expiration != null ? {
        noncurrent_days = rule.noncurrent_version_expiration
      } : {}

      transition = [
        for t in try(rule.transition, []) : {
          days          = t.days
          storage_class = t.storage_class
        }
      ]
    }
  ] : []

  tags = local.common_tags
}
