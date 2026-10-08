# =========================================================================
# Input guard
# =========================================================================
# Cross-variable validation blocks require Terraform >= 1.9; this module targets
# >= 1.5.7, so enforce the replication inputs with resource preconditions.
resource "terraform_data" "replication_guard" {
  count = local.replication_enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = try(trimspace(local.replica_region), "") != "" && local.replica_region != var.region
      error_message = "replication_configuration.enabled = true requires a non-empty region that differs from the source region (var.region)."
    }

    precondition {
      condition     = var.kms_key_arn == null || local.replica_kms_key_arn != null
      error_message = "When kms_key_arn is set and replication is enabled, replication_configuration.kms_key_arn (a replica-region key) must also be set, because KMS keys are regional."
    }
  }
}

# =========================================================================
# Source bucket (created in var.region via the aws.source alias)
# =========================================================================
module "source_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  providers = {
    aws = aws.source
  }

  bucket        = local.source_bucket_name
  force_destroy = var.force_destroy

  versioning = {
    enabled = local.versioning_enabled
  }

  # Security best practices - block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = local.source_sse_config

  # Attach replication only when a replica is being created.
  replication_configuration = local.replication_enabled ? {
    role  = aws_iam_role.replication[0].arn
    rules = local.replication_rules
  } : { role = null, rules = null }

  tags = local.common_tags
}

# =========================================================================
# Replica bucket (replica region — aliased aws.replica provider)
# =========================================================================
module "replica_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  count = local.replication_enabled ? 1 : 0

  providers = {
    aws = aws.replica
  }

  bucket        = local.replica_bucket_name
  force_destroy = var.force_destroy

  # Versioning is mandatory on a replication target.
  versioning = {
    enabled = true
  }

  # Security best practices - block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = local.replica_sse_config

  tags = merge(local.common_tags, { Role = "replica" })
}
