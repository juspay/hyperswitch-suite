# =============================================================================
# Bootstrap backend - local, on purpose
# =============================================================================
# This root creates the Object Storage bucket that every other OCI root's state
# will live in. It cannot store its own state there before it exists, so it uses
# a local backend. That is the whole bootstrapping problem, and it is the same
# shape as terraform/aws/bootstrap/dev/.
#
# After the bucket exists, this root's state can optionally be migrated into it:
#
#   1. Replace the block below with:
#
#        terraform {
#          backend "oci" {
#            bucket    = "hyperswitch-dev-ap-mumbai-1-terraform-state"
#            namespace = "<object-storage-namespace>"
#            region    = "ap-mumbai-1"
#            key       = "bootstrap/terraform.tfstate"
#            auth      = "SecurityToken"
#          }
#        }
#
#   2. terraform init -migrate-state
#
# WARNING: once migrated, this root can no longer destroy its own bucket without
# migrating the state back out to local first.
#
# `terraform.tfstate` here is a real artifact of a real apply - treat it the way
# the AWS bootstrap root's local state is treated, not as scratch.
# =============================================================================

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
