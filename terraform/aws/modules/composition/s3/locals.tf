locals {
  name_prefix = "${var.project_name}-${var.environment}"

  replication_enabled = var.replication_configuration.enabled
  replica_region      = var.replication_configuration.region
  replica_kms_key_arn = var.replication_configuration.kms_key_arn

  # Replicate SSE-KMS objects only when the source bucket is KMS-encrypted.
  kms_replication = local.replication_enabled && var.kms_key_arn != null

  # Bucket names: use the explicit input, else derive from project/env/region.
  source_bucket_name = coalesce(var.bucket_name, "${local.name_prefix}-${var.region}")
  replica_bucket_name = local.replication_enabled ? coalesce(
    var.replication_configuration.bucket_name,
    "${local.name_prefix}-${local.replica_region}",
  ) : null

  # Cross-region replication requires versioning on the source bucket, so force
  # it on when replication is enabled regardless of the versioning_enabled input.
  versioning_enabled = local.replication_enabled ? true : var.versioning_enabled

  # SSE-KMS when a key is provided, otherwise SSE-S3 (AES256). kms_master_key_id
  # is only set for the KMS case to avoid a permanent diff against AES256. KMS
  # keys are regional, so the source and replica use their own keys.
  source_sse_config = {
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

  replica_sse_config = {
    rule = merge(
      {
        apply_server_side_encryption_by_default = merge(
          { sse_algorithm = local.replica_kms_key_arn != null ? "aws:kms" : "AES256" },
          local.replica_kms_key_arn != null ? { kms_master_key_id = local.replica_kms_key_arn } : {},
        )
      },
      { bucket_key_enabled = true },
    )
  }

  # Single replication rule, assembled with KMS bits only when the source is
  # KMS-encrypted.
  replication_rules = local.replication_enabled ? [
    merge(
      {
        id                        = var.replication_configuration.rule_id
        status                    = "Enabled"
        priority                  = 10
        delete_marker_replication = true

        destination = merge(
          {
            bucket        = module.replica_bucket[0].s3_bucket_arn
            storage_class = var.replication_configuration.storage_class
          },
          local.kms_replication ? { replica_kms_key_id = local.replica_kms_key_arn } : {},
        )
      },
      local.kms_replication ? {
        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }
      } : {},
    )
  ] : []

  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform-IaC"
    },
    var.tags,
  )

  source_bucket_arn  = "arn:aws:s3:::${local.source_bucket_name}"
  replica_bucket_arn = local.replication_enabled ? "arn:aws:s3:::${local.replica_bucket_name}" : null
}
