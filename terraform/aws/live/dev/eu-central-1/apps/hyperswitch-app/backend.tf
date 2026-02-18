terraform {
  backend "s3" {
    bucket              = "hyperswitch-dev-terraform-state"
    key                 = "dev/eu-central-1/apps/hyperswitch-app/terraform.tfstate"
    region              = "eu-central-1"
    encrypt             = true
  }
}