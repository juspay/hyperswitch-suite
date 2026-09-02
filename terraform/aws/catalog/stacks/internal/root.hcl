# =============================================================================
# Internal stack — root configuration
# =============================================================================
# Values-driven root for the internal dev / pre-prod / prod deployments.
# All environment-specific settings come from the stack `values` supplied by
# terraform/aws/live/terragrunt.stack.hcl.
#
# Differences from stacks/standalone:
#   - three named environments (dev, pre-prod, prod) instead of prod/sandbox
#   - the VPC is created by this stack (catalog/units/vpc-network), not
#     merchant-provided — units pick this up automatically because `values`
#     never sets vpc_id (see units/database/terragrunt.hcl:11-13,41 for the
#     BYO-VPC-vs-created-VPC pattern every VPC-consuming unit implements)
# =============================================================================

locals {
  # values.env must be one of the keys below; anything else is a hard error
  # rather than silently collapsing into another environment's state prefix.
  env_map = {
    "dev"      = { full = "dev", short = "dev" }
    "pre-prod" = { full = "pre-prod", short = "prep" }
    "prod"     = { full = "prod", short = "prd" }
  }

  environment     = local.env_map[values.env]
  region          = values.region
  project_name    = values.project_name
  account_id      = values.account_id
  deployment_tier = values.env == "prod" ? "prod" : "staging"
  region_code     = try(values.region_code, values.region)
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket                = values.state_bucket
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

  contents = <<EOF
provider "aws" {
  region = "${local.region}"

  default_tags {
    tags = {
      Project   = "${local.project_name}"
      ManagedBy = "hyperswitch-terragrunt"
    }
  }
}
EOF
}
