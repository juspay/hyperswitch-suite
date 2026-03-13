terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  # backend "s3" {
  #   bucket  = "hyperswitch-sbx-terraform-state"
  #   key     = "dev/eu-central-1/jump-host/terraform.tfstate"
  #   region  = "eu-central-1"
  #   encrypt = true
  # }
}
