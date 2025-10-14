provider "aws" {
  region = var.region
}

# Use the existing s3-bucket base module to create state bucket
module "terraform_state_bucket" {
  source = "../../modules/base/s3-bucket"

  bucket_name       = var.state_bucket_name
  force_destroy     = var.allow_destroy
  enable_versioning = true
  versioning_status = "Enabled"

  # Encryption (required for state files)
  sse_algorithm = "AES256"

  # Block all public access (critical for state files!)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # No lifecycle rules - keep all state history
  lifecycle_rules = []

  tags = {
    Name        = var.state_bucket_name
    Environment = var.environment
    Purpose     = "terraform-state"
    ManagedBy   = "terraform-bootstrap"
    Project     = "hyperswitch"
  }
}

# Bucket policy to enforce TLS (prevent unencrypted access)
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = module.terraform_state_bucket.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.terraform_state_bucket.bucket_arn,
          "${module.terraform_state_bucket.bucket_arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
