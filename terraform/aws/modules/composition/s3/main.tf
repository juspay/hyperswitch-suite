# =========================================================================
# Input guard
# =========================================================================
# Cross-variable validation blocks require Terraform >= 1.9; this module targets
# >= 1.5, so enforce the replication inputs with a resource precondition instead.
resource "terraform_data" "replication_guard" {
  count = var.enable_replication ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.replica_region != null && var.replica_bucket_name != null
      error_message = "enable_replication = true requires both replica_region and replica_bucket_name to be set."
    }
  }
}

# =========================================================================
# Source bucket (primary region — default aws provider)
# =========================================================================
module "source_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  bucket        = var.source_bucket_name
  force_destroy = var.force_destroy

  versioning = {
    enabled = local.versioning_enabled
  }

  # Security best practices - block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = local.sse_config

  # Attach replication only when a replica is being created.
  replication_configuration = var.enable_replication ? {
    role = aws_iam_role.replication[0].arn
    rules = [
      {
        id                        = var.replication_rule_id
        status                    = "Enabled"
        priority                  = 10
        delete_marker_replication = true

        destination = {
          bucket        = module.replica_bucket[0].s3_bucket_arn
          storage_class = var.replica_storage_class
        }
      }
    ]
  } : {}

  tags = local.common_tags
}

# =========================================================================
# Replica bucket (replica region — aliased aws.replica provider)
# =========================================================================
module "replica_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  count = var.enable_replication ? 1 : 0

  providers = {
    aws = aws.replica
  }

  bucket        = var.replica_bucket_name
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

  server_side_encryption_configuration = local.sse_config

  tags = merge(local.common_tags, { Role = "replica" })
}
