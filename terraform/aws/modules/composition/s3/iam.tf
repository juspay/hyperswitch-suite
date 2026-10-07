# =========================================================================
# IAM role assumed by S3 to perform cross-region replication
# =========================================================================
# Created only when replication is enabled. Bucket ARNs are built from the
# resolved bucket names (not module outputs) so the policy does not depend on the
# bucket modules, keeping the dependency graph acyclic.
#
# The role name is derived from the source bucket name (bounded to IAM's 64-char
# limit) so multiple instances of this module in the same account/env do not
# collide on an identical role name.

data "aws_iam_policy_document" "replication_assume" {
  count = local.replication_enabled ? 1 : 0

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
  count = local.replication_enabled ? 1 : 0

  # Truncate the bucket portion (<=48) so the disambiguating suffix always
  # survives IAM's 64-char role-name limit.
  name               = "${substr(local.source_bucket_name, 0, 48)}-s3-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_assume[0].json

  tags = local.common_tags
}

data "aws_iam_policy_document" "replication" {
  count = local.replication_enabled ? 1 : 0

  statement {
    sid       = "AllowReadReplicationConfigAndList"
    effect    = "Allow"
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [local.source_bucket_arn]
  }

  statement {
    sid    = "AllowReadSourceObjects"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${local.source_bucket_arn}/*"]
  }

  statement {
    sid    = "AllowReplicateToDestination"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${local.replica_bucket_arn}/*"]
  }

  # SSE-KMS replication: decrypt source objects with the source-region key,
  # re-encrypt on the destination with the replica-region key. S3 uses
  # GenerateDataKey (not Encrypt) to write replicated objects. Both statements
  # are scoped to S3 in the respective region via kms:ViaService.
  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      sid       = "AllowDecryptSourceKmsKey"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [var.kms_key_arn]

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${var.region}.amazonaws.com"]
      }
    }
  }

  dynamic "statement" {
    for_each = local.kms_replication ? [1] : []
    content {
      sid       = "AllowEncryptDestinationKmsKey"
      effect    = "Allow"
      actions   = ["kms:Encrypt", "kms:GenerateDataKey"]
      resources = [local.replica_kms_key_arn]

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${coalesce(local.replica_region, var.region)}.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_role_policy" "replication" {
  count = local.replication_enabled ? 1 : 0

  name   = "replication"
  role   = aws_iam_role.replication[0].id
  policy = data.aws_iam_policy_document.replication[0].json
}
