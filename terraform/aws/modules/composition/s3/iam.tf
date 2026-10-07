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

  name               = substr("${local.source_bucket_name}-s3-replication", 0, 64)
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

  # SSE-KMS replication: decrypt source objects with the source key, re-encrypt
  # on the destination with the replica-region key.
  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      sid       = "AllowDecryptSourceKmsKey"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [var.kms_key_arn]
    }
  }

  dynamic "statement" {
    for_each = local.kms_replication ? [1] : []
    content {
      sid       = "AllowEncryptDestinationKmsKey"
      effect    = "Allow"
      actions   = ["kms:Encrypt"]
      resources = [local.replica_kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "replication" {
  count = local.replication_enabled ? 1 : 0

  name   = substr("${local.source_bucket_name}-s3-replication", 0, 64)
  role   = aws_iam_role.replication[0].id
  policy = data.aws_iam_policy_document.replication[0].json
}
