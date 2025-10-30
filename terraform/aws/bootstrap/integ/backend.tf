# ============================================================================
# Local Backend for Bootstrap
# ============================================================================
# The bootstrap layer uses a LOCAL backend because it creates the S3 bucket
# and DynamoDB table that will be used by other deployments.
#
# This is a chicken-and-egg problem: you can't store the state in S3 until
# the S3 bucket exists, so bootstrap must use local state.
#
# IMPORTANT: Protect this local state file! It contains the configuration
# for your remote backend infrastructure.
# ============================================================================

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
