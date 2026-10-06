include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# The module glues two regions (configuration_aliases = [aws, aws.replica]). The
# default aws provider comes from the environment's root.hcl; this supplies the
# aws.replica alias for the destination region.
generate "provider_replica" {
  path      = "provider_replica.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  alias  = "replica"
  region = "${values.replica_region}"
}
EOF
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/s3-bucket-replication?ref=s3-bucket-replication-v0.1.0"
}

inputs = {
  source_bucket_name      = values.source_bucket_name
  destination_bucket_name = values.destination_bucket_name

  create_source_bucket      = try(values.create_source_bucket, true)
  create_destination_bucket = try(values.create_destination_bucket, true)

  replication_prefix       = try(values.replication_prefix, null)
  replicate_delete_markers = try(values.replicate_delete_markers, true)
  sse_algorithm            = try(values.sse_algorithm, "AES256")
  source_kms_key_arn       = try(values.source_kms_key_arn, null)
  destination_kms_key_arn  = try(values.destination_kms_key_arn, null)
  replication_role_name    = try(values.replication_role_name, null)
  force_destroy            = try(values.force_destroy, false)

  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }
}
