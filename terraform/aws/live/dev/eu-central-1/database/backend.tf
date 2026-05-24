terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }

  backend "s3" {
    bucket  = "hyperswitch-dev-terraform-state"
    key     = "dev/eu-central-1/database/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}
