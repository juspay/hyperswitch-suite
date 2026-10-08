# Buckets are pinned to explicit regions via these aliases, independent of the
# caller's default provider: source = var.region, replica = the replica region.
provider "aws" {
  alias  = "source"
  region = var.region
}

provider "aws" {
  alias  = "replica"
  region = coalesce(var.replication_configuration.region, var.region)
}
