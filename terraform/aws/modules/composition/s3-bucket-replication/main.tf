# ============================================================================
# Same-account S3 Cross-Region Replication — glue only.
# ============================================================================
# All logic (bucket, versioning, SSE, the replication rule and the IAM role)
# lives in base/s3-bucket. This module just wires two base instances across two
# regions: a destination (replica) bucket via aws.replica, and the source bucket
# (created or pre-existing) whose replication rule + role point at it.
#
# Caller passes both providers:
#   providers = { aws = aws, aws.replica = aws.<replica-region> }
#
# NOTE: auto-creation of a multi-region KMS key is intentionally NOT here (that's
# logic, not glue). For sse_algorithm = "aws:kms", pass existing key ARNs.
# Live replication only covers NEW writes — backfill existing objects with a
# one-time S3 Batch Replication job.
# ============================================================================

data "aws_partition" "current" {}

locals {
  destination_bucket_arn = coalesce(
    one(module.destination[*].bucket_arn),
    "arn:${data.aws_partition.current.partition}:s3:::${var.destination_bucket_name}",
  )
}

# Destination (replica) bucket in the aws.replica region.
module "destination" {
  source = "../../base/s3-bucket"
  count  = var.create_destination_bucket ? 1 : 0

  providers = {
    aws = aws.replica
  }

  bucket_name       = var.destination_bucket_name
  force_destroy     = var.force_destroy
  enable_versioning = true
  versioning_status = "Enabled"
  sse_algorithm     = var.sse_algorithm
  kms_master_key_id = var.destination_kms_key_arn

  tags = merge(
    var.tags,
    {
      Name    = var.destination_bucket_name
      Purpose = "s3-replication-destination"
    }
  )
}

# Source bucket (created or pre-existing) + replication rule + role, via base.
module "source" {
  source = "../../base/s3-bucket"

  bucket_name   = var.source_bucket_name
  create_bucket = var.create_source_bucket
  force_destroy = var.force_destroy

  enable_versioning = true
  versioning_status = "Enabled"
  sse_algorithm     = var.sse_algorithm
  kms_master_key_id = var.source_kms_key_arn

  enable_replication      = true
  create_replication_role = true
  replication_role_name   = var.replication_role_name

  replication_rules = [
    {
      id                        = var.replication_rule_id
      prefix                    = var.replication_prefix
      destination_bucket_arn    = local.destination_bucket_arn
      destination_storage_class = var.destination_storage_class
      replica_kms_key_id        = var.destination_kms_key_arn
      delete_marker_replication = var.replicate_delete_markers
    }
  ]

  tags = merge(
    var.tags,
    {
      Name    = var.source_bucket_name
      Purpose = "s3-replication-source"
    }
  )
}