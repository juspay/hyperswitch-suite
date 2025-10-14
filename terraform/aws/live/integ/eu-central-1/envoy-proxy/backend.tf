# Integration environment uses S3 backend
terraform {
  backend "s3" {
    bucket         = "hyperswitch-terraform-state"
    key            = "integ/eu-central-1/envoy-proxy/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
