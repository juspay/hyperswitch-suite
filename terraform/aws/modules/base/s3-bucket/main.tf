data "aws_partition" "current" {}

locals {
  # Name/ARN of the managed bucket when created, or of the referenced existing
  # bucket when create_bucket = false (lets replication attach to a pre-existing
  # bucket without this module managing it).
  bucket_id  = coalesce(one(aws_s3_bucket.this[*].id), var.bucket_name)
  bucket_arn = var.create_bucket ? one(aws_s3_bucket.this[*].arn) : "arn:${data.aws_partition.current.partition}:s3:::${var.bucket_name}"

  # Replication role: created from replication_rules when create_replication_role
  # is set, otherwise the caller supplies an existing role ARN.
  manage_replication_role        = var.enable_replication && var.create_replication_role
  replication_role_name_resolved = coalesce(var.replication_role_name, substr("s3-crr-${var.bucket_name}", 0, 64))
  replication_role_arn           = local.manage_replication_role ? one(aws_iam_role.replication[*].arn) : var.replication_role_arn

  # Object-level perms scoped to each rule's prefix (whole bucket when null).
  replication_source_resources      = [for r in var.replication_rules : "${local.bucket_arn}/${r.prefix != null ? r.prefix : ""}*"]
  replication_destination_resources = [for r in var.replication_rules : "${r.destination_bucket_arn}/${r.prefix != null ? r.prefix : ""}*"]
  replication_destination_kms_keys  = compact([for r in var.replication_rules : r.replica_kms_key_id])
}

resource "aws_s3_bucket" "this" {
  count         = var.create_bucket ? 1 : 0
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

# Public access block
resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_master_key_id : null
    }
    bucket_key_enabled = var.sse_algorithm == "aws:kms" ? true : false
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "this" {
  count  = var.create_bucket && var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = var.versioning_status
  }
}

# Lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.create_bucket && length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # Always include a filter block (required by AWS provider)
      filter {
        prefix = rule.value.prefix
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_version_expiration
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }
}

# IAM role S3 assumes to replicate FROM this bucket (optional; built from the rules).
data "aws_iam_policy_document" "replication_assume" {
  count = local.manage_replication_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication" {
  count              = local.manage_replication_role ? 1 : 0
  name               = local.replication_role_name_resolved
  assume_role_policy = data.aws_iam_policy_document.replication_assume[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "replication" {
  count = local.manage_replication_role ? 1 : 0

  statement {
    sid       = "AllowSourceBucketRead"
    effect    = "Allow"
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [local.bucket_arn]
  }

  statement {
    sid       = "AllowSourceObjectRead"
    effect    = "Allow"
    actions   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
    resources = local.replication_source_resources
  }

  statement {
    sid       = "AllowDestinationReplicate"
    effect    = "Allow"
    actions   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags", "s3:ObjectOwnerOverrideToBucketOwner"]
    resources = local.replication_destination_resources
  }

  # KMS for SSE-KMS replication: decrypt the source key, encrypt with the replica keys.
  dynamic "statement" {
    for_each = length(local.replication_destination_kms_keys) > 0 ? [1] : []
    content {
      sid       = "AllowKmsForReplication"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
      resources = concat(var.kms_master_key_id != null ? [var.kms_master_key_id] : [], local.replication_destination_kms_keys)
    }
  }
}

resource "aws_iam_role_policy" "replication" {
  count  = local.manage_replication_role ? 1 : 0
  name   = "${local.replication_role_name_resolved}-policy"
  role   = aws_iam_role.replication[0].id
  policy = data.aws_iam_policy_document.replication[0].json
}

# Replication (source side). Attaches to the created bucket, or to a pre-existing
# bucket when create_bucket = false. Requires versioning on both source and destination.
resource "aws_s3_bucket_replication_configuration" "this" {
  count  = var.enable_replication ? 1 : 0
  role   = local.replication_role_arn
  bucket = local.bucket_id

  dynamic "rule" {
    for_each = var.replication_rules
    content {
      id       = rule.value.id
      status   = rule.value.status
      priority = rule.value.priority

      # Empty filter block selects the whole bucket (V2 replication);
      # a prefix narrows the scope when provided.
      filter {
        prefix = rule.value.prefix
      }

      # Required for V2 (filter-based) replication rules.
      delete_marker_replication {
        status = rule.value.delete_marker_replication ? "Enabled" : "Disabled"
      }

      # Only replicate SSE-KMS encrypted objects when a replica key is given.
      dynamic "source_selection_criteria" {
        for_each = rule.value.replica_kms_key_id != null ? [1] : []
        content {
          sse_kms_encrypted_objects {
            status = "Enabled"
          }
        }
      }

      destination {
        bucket        = rule.value.destination_bucket_arn
        storage_class = rule.value.destination_storage_class

        dynamic "encryption_configuration" {
          for_each = rule.value.replica_kms_key_id != null ? [1] : []
          content {
            replica_kms_key_id = rule.value.replica_kms_key_id
          }
        }
      }
    }
  }

  # Versioning must exist before a replication configuration can be applied
  # (for a created bucket; a pre-existing bucket must already be versioned).
  depends_on = [aws_s3_bucket_versioning.this]
}

# ---------------------------------------------------------------------------
# count was added to the bucket + its PAB/SSE sub-resources to support
# create_bucket = false. These keep already-deployed buckets (e.g. the state
# bucket, squid-proxy) from being destroyed/recreated by the address change.
# ---------------------------------------------------------------------------
moved {
  from = aws_s3_bucket.this
  to   = aws_s3_bucket.this[0]
}

moved {
  from = aws_s3_bucket_public_access_block.this
  to   = aws_s3_bucket_public_access_block.this[0]
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.this
  to   = aws_s3_bucket_server_side_encryption_configuration.this[0]
}
