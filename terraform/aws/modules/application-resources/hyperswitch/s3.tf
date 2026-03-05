# =========================================================================
# S3 BUCKET - Dashboard Themes
# =========================================================================

locals {
  s3_dashboard_themes_bucket_name = try(var.s3_dashboard_themes.bucket_name, null) != null ? var.s3_dashboard_themes.bucket_name : "${local.name_prefix}-dashboard-themes"
}

module "s3_dashboard_themes" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  count = local.s3_dashboard_themes_create ? 1 : 0

  bucket        = local.s3_dashboard_themes_bucket_name
  force_destroy = try(var.s3_dashboard_themes.force_destroy, false)

  # Versioning
  versioning = {
    enabled = try(var.s3_dashboard_themes.versioning_enabled, true)
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

  tags = local.common_tags
}

# =========================================================================
# S3 BUCKET - File Uploads
# =========================================================================

locals {
  s3_file_uploads_bucket_name = try(var.s3_file_uploads.bucket_name, null) != null ? var.s3_file_uploads.bucket_name : "${local.name_prefix}-file-uploads"
}

module "s3_file_uploads" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  count = local.s3_file_uploads_create ? 1 : 0

  bucket        = local.s3_file_uploads_bucket_name
  force_destroy = try(var.s3_file_uploads.force_destroy, false)

  # Versioning
  versioning = {
    enabled = try(var.s3_file_uploads.versioning_enabled, true)
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

  tags = local.common_tags
}
