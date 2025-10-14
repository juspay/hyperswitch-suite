# Bootstrap uses LOCAL backend
# This is a special case - we need local state to create the S3 bucket
# that will store all other states

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# After running this, you can update your other deployments to use S3:
#
# terraform {
#   backend "s3" {
#     bucket  = "hyperswitch-dev-terraform-state"
#     key     = "dev/eu-central-1/SERVICE_NAME/terraform.tfstate"
#     region  = "eu-central-1"
#     encrypt = true
#   }
# }
