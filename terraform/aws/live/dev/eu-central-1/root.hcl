locals {
  environment  = { full = "dev", short = "dev" }
  region       = "eu-central-1"
  project_name = "hyperswitch"
  account_id   = "123456789012"

  state_bucket_name = "hyperswitch-dev-terraform-state"

  availability_zones = [
    "eu-central-1a",
    "eu-central-1b",
    "eu-central-1c",
  ]

  vpc_cidr = "10.0.0.0/16"

  vpn_cidr_blocks = ["203.0.113.0/32"]
  office_ips      = ["198.51.100.0/29", "198.51.100.64/32"]

  domain_name = "dev.hyperswitch.com"

  tags = {
    Environment = "dev"
    Team        = "Infra"
    ManagedBy   = "Terraform"
    Project     = "hyperswitch"
  }
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket                = local.state_bucket_name
    key                   = "${local.environment.full}/${local.region}/${path_relative_to_include()}/terraform.tfstate"
    region                = local.region
    encrypt               = true
    use_lockfile          = true
    disable_bucket_update = true
  }

  disable_init = false
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOP
provider "aws" {
  region = "${local.region}"
}
EOP
}
