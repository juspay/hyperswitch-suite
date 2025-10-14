# Development environment uses LOCAL backend for easy testing
# State file will be stored locally in terraform.tfstate

# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

terraform {
     backend "s3" {
       bucket  = "hyperswitch-dev-terraform-state"
       key     = "dev/eu-central-1/squid-proxy/terraform.tfstate"
       region  = "eu-central-1"
       encrypt = true
     }
   }
