terraform {
  backend "s3" {
    bucket  = "hyperswitch-dev-terraform-state"
    key     = "dev/eu-central-1/misc/recon/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}
