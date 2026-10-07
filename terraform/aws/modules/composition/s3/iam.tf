# =========================================================================
# IAM role assumed by S3 to perform cross-region replication
# =========================================================================
# Created only when replication is enabled. Bucket ARNs are built from the name
# variables (not module outputs) so the policy does not depend on the bucket
# modules, keeping the dependency graph acyclic.

data "aws_iam_policy_document" "replication_assume" {
  count = var.enable_replication ? 1 : 0

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
  count = var.enable_replication ? 1 : 0

  name               = "${local.name_prefix}-s3-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_assume[0].json

  tags = local.common_tags
}

data "aws_iam_policy_document" "replication" {
  count = var.enable_replication ? 1 : 0

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
}

resource "aws_iam_role_policy" "replication" {
  count = var.enable_replication ? 1 : 0

  name   = "${local.name_prefix}-s3-replication"
  role   = aws_iam_role.replication[0].id
  policy = data.aws_iam_policy_document.replication[0].json
}
