locals {
  name_prefix = "${var.project_name}-${var.environment}"

  replication_enabled = var.replication_configuration.enabled
  replica_region      = var.replication_configuration.region
  replica_kms_key_arn = var.replication_configuration.kms_key_arn

  # Two-way replication: the replica bucket also replicates back to the source.
  # Only meaningful when replication is enabled.
  bidirectional = local.replication_enabled && var.replication_configuration.bidirectional

  # Replicate SSE-KMS objects only when the source bucket is KMS-encrypted.
  kms_replication = local.replication_enabled && var.kms_key_arn != null

  # One entry per active replication direction, driving the IAM for_each. Each
  # entry carries the source/destination bucket ARNs, the regional KMS keys, and
  # the regions used in the kms:ViaService conditions. "fwd" is source -> replica
  # (always present when replication is enabled); "rev" is replica -> source
  # (present only in bidirectional mode). The role name is derived from each
  # direction's own source bucket so "fwd" keeps its historical name.
  replication_directions = local.replication_enabled ? merge(
    {
      fwd = {
        source_bucket_name = local.source_bucket_name
        source_bucket_arn  = local.source_bucket_arn
        dest_bucket_arn    = local.replica_bucket_arn
        source_kms_arn     = var.kms_key_arn
        dest_kms_arn       = local.replica_kms_key_arn
        source_region      = var.region
        dest_region        = local.replica_region
      }
    },
    local.bidirectional ? {
      rev = {
        source_bucket_name = local.replica_bucket_name
        source_bucket_arn  = local.replica_bucket_arn
        dest_bucket_arn    = local.source_bucket_arn
        source_kms_arn     = local.replica_kms_key_arn
        dest_kms_arn       = var.kms_key_arn
        source_region      = local.replica_region
        dest_region        = var.region
      }
    } : {},
  ) : {}

  # Bucket names: use the explicit input, else derive from project/env/region.
  source_bucket_name = coalesce(var.bucket_name, "${local.name_prefix}-${var.region}")
  # coalesce evaluates all arguments, so the derived fallback must never
  # interpolate a null region (that throws a raw template error at plan time,
  # masking the replication_guard message). Fall back to var.region when the
  # replica region is unset; the guard still blocks the real misconfiguration.
  replica_bucket_name = local.replication_enabled ? coalesce(
    var.replication_configuration.bucket_name,
    "${local.name_prefix}-${coalesce(local.replica_region, var.region)}",
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

  # source_selection_criteria for each direction. sse_kms_encrypted_objects opts
  # KMS-encrypted objects into replication (only when KMS is in use);
  # replica_modifications syncs metadata-only changes made on replica objects
  # back to their origin and is required for a correct two-way mirror. The key is
  # emitted only when non-empty so one-way, non-KMS configs stay byte-identical.
  forward_source_selection_criteria = merge(
    local.kms_replication ? { sse_kms_encrypted_objects = { enabled = true } } : {},
    local.bidirectional ? { replica_modifications = { enabled = true } } : {},
  )
  reverse_source_selection_criteria = merge(
    local.kms_replication ? { sse_kms_encrypted_objects = { enabled = true } } : {},
    { replica_modifications = { enabled = true } },
  )

  # Forward rule (source -> replica), assembled with KMS bits only when the
  # source is KMS-encrypted. The destination references the replica bucket's
  # module output so Terraform creates the replica bucket before putting this
  # replication configuration (acyclic: buckets never depend on replication
  # configs). delete_marker_replication keeps deletes in sync across the pair.
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
      length(local.forward_source_selection_criteria) > 0 ? {
        source_selection_criteria = local.forward_source_selection_criteria
      } : {},
    )
  ] : []

  # Reverse rule (replica -> source), only in bidirectional mode. Mirrors the
  # forward rule: destination is the source bucket (its module output gives the
  # create-before-replicate ordering), the destination KMS key is the
  # source-region key, and replica_modifications is always on.
  reverse_replication_rules = local.bidirectional ? [
    merge(
      {
        id                        = var.replication_configuration.reverse_rule_id
        status                    = "Enabled"
        priority                  = 10
        delete_marker_replication = true

        destination = merge(
          {
            bucket        = module.source_bucket.s3_bucket_arn
            storage_class = var.replication_configuration.reverse_storage_class
          },
          local.kms_replication ? { replica_kms_key_id = var.kms_key_arn } : {},
        )
      },
      {
        source_selection_criteria = local.reverse_source_selection_criteria
      },
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
