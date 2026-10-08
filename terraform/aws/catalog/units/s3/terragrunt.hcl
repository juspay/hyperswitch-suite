include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/s3?ref=s3-v0.1.0"
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  # Source bucket. When s3_bucket_name is unset the module derives
  # "<project_name>-<environment>-<region>".
  bucket_name        = try(values.s3_bucket_name, null)
  force_destroy      = try(values.s3_force_destroy, false)
  versioning_enabled = try(values.s3_versioning_enabled, true)
  kms_key_arn        = try(values.s3_kms_key_arn, null)
  bucket_region      = try(values.s3_bucket_region, null)

  # Optional cross-region replication. The replica provider alias lives inside
  # the module (driven by replication_configuration.region), so no provider
  # plumbing is needed here.
  replication_configuration = {
    enabled       = try(values.s3_replication_enabled, false)
    region        = try(values.s3_replica_region, null)
    bucket_name   = try(values.s3_replica_bucket_name, null)
    storage_class = try(values.s3_replica_storage_class, "STANDARD")
    kms_key_arn   = try(values.s3_replica_kms_key_arn, null)
    rule_id       = try(values.s3_replication_rule_id, "replicate-all")
  }

  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }
}
