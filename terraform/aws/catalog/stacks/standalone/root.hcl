# =============================================================================
# Standalone (self-host) stack — root configuration
# =============================================================================
# Values-driven root for a single-region, self-hosted Hyperswitch deployment.
# All environment-specific settings come from the stack `values` supplied by
# the live terragrunt.stack.hcl (rendered by scripts/self-host/generate.sh).
#
# Differences from the internal stacks:
#   - no Atlantis / management-cluster assume-role wiring
#   - state bucket name is explicit (values.state_bucket), no naming convention
# =============================================================================

locals {
  environment     = values.env == "prod" ? { full = "prod", short = "prd" } : { full = "sandbox", short = "sbx" }
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
      ManagedBy = "hyperswitch-self-host"
    }
  }
}
EOF
}
