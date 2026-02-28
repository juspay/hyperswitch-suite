# ============================================================================
# Terraform Backend Infrastructure
# ============================================================================
# This module creates the complete backend infrastructure for Terraform:
#   - S3 bucket for state storage (with versioning and encryption)
#   - DynamoDB table for state locking
#   - Bucket policy to enforce TLS/encryption
#
# Usage:
#   module "terraform_backend" {
#     source = "../../modules/composition/terraform-backend"
#
#     environment         = "dev"
#     project_name        = "hyperswitch"
#     state_bucket_name   = "hyperswitch-dev-terraform-state"
#     dynamodb_table_name = "hyperswitch-dev-terraform-state-lock"
#   }
# ============================================================================

# S3 bucket for Terraform state
module "state_bucket" {
  source = "../../base/s3-bucket"

  create            = var.create
  bucket_name       = var.state_bucket_name
  force_destroy     = var.allow_destroy
  enable_versioning = true
  versioning_status = "Enabled"

  # Encryption (required for state files)
  sse_algorithm = var.sse_algorithm
  kms_master_key_id = var.kms_master_key_id

  # Block all public access (critical for state files!)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # No lifecycle rules - keep all state history by default
  lifecycle_rules = var.lifecycle_rules

  tags = merge(
    var.tags,
    {
      Name        = var.state_bucket_name
      Environment = var.environment
      Purpose     = "terraform-state"
      ManagedBy   = "terraform-bootstrap"
      Project     = var.project_name
    }
  )
}

# Bucket policy to enforce TLS (prevent unencrypted access)
resource "aws_s3_bucket_policy" "enforce_tls" {
  count = var.create ? 1 : 0

  bucket = module.state_bucket.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          try(module.state_bucket.bucket_arn, ""),
          "${try(module.state_bucket.bucket_arn, "")}/*"
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

# DynamoDB table for state locking
module "lock_table" {
  source = "../../base/dynamodb-table"

  create       = var.create
  table_name   = var.dynamodb_table_name
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "LockID"

  # LockID is the required attribute for Terraform state locking
  attributes = [
    {
      name = "LockID"
      type = "S"  # String type
    }
  ]

  # Only used if billing_mode = "PROVISIONED"
  read_capacity  = var.dynamodb_read_capacity
  write_capacity = var.dynamodb_write_capacity

  # Enable point-in-time recovery for additional safety
  enable_point_in_time_recovery = var.enable_dynamodb_pitr

  # Server-side encryption (enabled by default)
  enable_encryption = true
  kms_key_arn      = var.dynamodb_kms_key_arn

  tags = merge(
    var.tags,
    {
      Name        = var.dynamodb_table_name
      Environment = var.environment
      Purpose     = "terraform-state-lock"
      ManagedBy   = "terraform-bootstrap"
      Project     = var.project_name
    }
  )
}
