terraform {
  backend "s3" {
    bucket  = "hyperswitch-dev-terraform-state"
    key     = "dev/eu-central-1/apps/keymanager/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}
