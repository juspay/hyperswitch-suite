locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Cross-region replication requires versioning on the source bucket, so force
  # it on when replication is enabled regardless of the versioning_enabled input.
  versioning_enabled = var.enable_replication ? true : var.versioning_enabled

  # SSE-KMS when a key is provided, otherwise SSE-S3 (AES256). kms_master_key_id
  # is only set for the KMS case to avoid a permanent diff against AES256.
  sse_config = {
    rule = merge(
      {
        apply_server_side_encryption_by_default = merge(
          { sse_algorithm = var.kms_key_arn != null ? "aws:kms" : "AES256" },
          var.kms_key_arn != null ? { kms_master_key_id = var.kms_key_arn } : {},
        )
      },
      { bucket_key_enabled = true },
    )
  }

  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform-IaC"
    },
    var.tags,
  )

  source_bucket_arn  = "arn:aws:s3:::${var.source_bucket_name}"
  replica_bucket_arn = var.enable_replication ? "arn:aws:s3:::${var.replica_bucket_name}" : null
}
