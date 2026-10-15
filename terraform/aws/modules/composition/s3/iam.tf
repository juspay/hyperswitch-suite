# =========================================================================
# IAM role(s) assumed by S3 to perform cross-region replication
# =========================================================================
# One role per active replication direction (local.replication_directions):
# "fwd" (source -> replica) is always present when replication is enabled, and
# "rev" (replica -> source) is added in bidirectional mode. Two direction-scoped
# roles (rather than one role covering both directions) keep each role
# least-privilege: a compromised role can only move data one way.
#
# Bucket ARNs are built from the resolved bucket names (not module outputs) so
# the policy does not depend on the bucket modules, keeping the graph acyclic.
# Each role name is derived from its direction's own source bucket (bounded to
# IAM's 64-char limit); "fwd" therefore keeps its historical name so existing
# one-way deployments do not force-replace the role.

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
  for_each = local.replication_directions

  # Truncate the bucket portion (<=48) so the "-s3-replication" suffix always
  # survives IAM's 64-char role-name limit.
  name               = "${substr(each.value.source_bucket_name, 0, 48)}-s3-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_assume[0].json

  tags = local.common_tags
}

data "aws_iam_policy_document" "replication" {
  for_each = local.replication_directions

  statement {
    sid       = "AllowReadReplicationConfigAndList"
    effect    = "Allow"
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [each.value.source_bucket_arn]
  }

  statement {
    sid    = "AllowReadSourceObjects"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${each.value.source_bucket_arn}/*"]
  }

  statement {
    sid    = "AllowReplicateToDestination"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${each.value.dest_bucket_arn}/*"]
  }

  # SSE-KMS replication: decrypt source objects with the source-region key,
  # re-encrypt on the destination with the destination-region key. S3 uses
  # GenerateDataKey (not just Encrypt) to write replicated objects. Both
  # statements are scoped to S3 in the respective region via kms:ViaService.
  dynamic "statement" {
    for_each = each.value.source_kms_arn != null ? [1] : []
    content {
      sid       = "AllowDecryptSourceKmsKey"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [each.value.source_kms_arn]

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${each.value.source_region}.amazonaws.com"]
      }
    }
  }

  dynamic "statement" {
    for_each = each.value.dest_kms_arn != null ? [1] : []
    content {
      sid       = "AllowEncryptDestinationKmsKey"
      effect    = "Allow"
      actions   = ["kms:Encrypt", "kms:GenerateDataKey"]
      resources = [each.value.dest_kms_arn]

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${each.value.dest_region}.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_role_policy" "replication" {
  for_each = local.replication_directions

  name   = "replication"
  role   = aws_iam_role.replication[each.key].id
  policy = data.aws_iam_policy_document.replication[each.key].json
}
