# Aliased provider for the replica region.
#
# Provider blocks cannot be conditional, so this is always declared but only
# consumed when replication is enabled (the replica bucket and its IAM wiring are
# count-gated). It falls back to the source region so the configuration is
# well-formed even when replication is disabled.
#
# The default (source-region) provider is supplied by the consuming layer — for
# Terragrunt roots that is the generated provider.tf from root.hcl.
provider "aws" {
  alias  = "replica"
  region = coalesce(var.replication_configuration.region, var.region)
}
