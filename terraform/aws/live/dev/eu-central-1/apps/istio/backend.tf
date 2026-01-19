# ============================================================================
# Remote state storage in S3 for Istio deployment
# ============================================================================

terraform {
  backend "s3" {
    bucket  = "hyperswitch-dev-terraform-state"
    key     = "dev/eu-central-1/apps/istio/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}
