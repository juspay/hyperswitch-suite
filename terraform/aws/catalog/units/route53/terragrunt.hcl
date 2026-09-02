include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/route53?ref=route53-v0.1.0"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  route53_zones = {
    "hyperswitch_public" = {
      name    = "${include.root.locals.deployment_tier}.${include.root.locals.region_code}.${values.base_domain}"
      comment = "Public Route 53 Zone for Hyperswitch"
      # Record targets (LB DNS names etc.) are environment-specific and are
      # supplied by the stack values, e.g.
      #   public_zone_records = {
      #     envoy_alb = { name = "api.<tier>.<region_code>.<base_domain>", type = "CNAME", ttl = 300, records = ["<alb-dns-name>"] }
      #   }
      records = try(values.public_zone_records, {})
    }
    "hyperswitch_internal" = {
      name    = "hyperswitch.internal"
      comment = "Internal Route 53 Zone for Hyperswitch"
      vpc = {
        vpc_id = dependency.vpc.outputs.vpc_id
      }
      records = try(values.internal_zone_records, {})
    }
  }

  tags = {
    Environment = include.root.locals.environment.short
    Team        = "Infra"
    ManagedBy   = "Terraform"
    Project     = include.root.locals.project_name
  }
}
