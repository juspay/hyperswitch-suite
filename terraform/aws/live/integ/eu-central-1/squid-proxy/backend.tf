# Integration environment uses S3 backend for state management
# This allows team collaboration and state locking

terraform {
  backend "s3" {
    bucket         = "hyperswitch-terraform-state"          # TODO: Create this bucket first
    key            = "integ/eu-central-1/squid-proxy/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"                 # TODO: Create this DynamoDB table

    # Optional: Use different AWS profile
    # profile = "hyperswitch-integ"
  }
}
