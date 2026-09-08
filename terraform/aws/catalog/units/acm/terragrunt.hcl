include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/acm?ref=acm-v0.1.0"
}

dependency "route53" {
  config_path = "../route53"

  mock_outputs = {
    zone_ids = {
      "hyperswitch_public" = "mock-zone_ids-hyperswitch_public"
    }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {

  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  certificates = {
    internal-alb = {
      domain_name                                 = "*.internal.${include.root.locals.deployment_tier}.${include.root.locals.region_code}.${values.base_domain}"
      subject_alternative_names                   = ["*.sso.internal.${include.root.locals.deployment_tier}.${include.root.locals.region_code}.${values.base_domain}"]
      zone_id                                     = dependency.route53.outputs.zone_ids["hyperswitch_public"]
      validation_method                           = "DNS"
      create_route53_records                      = true
      validate_certificate                        = true
      wait_for_validation                         = false
      validation_allow_overwrite_records          = false
      certificate_transparency_logging_preference = true
      tags = {
        Environment = include.root.locals.environment.full
        Project     = include.root.locals.project_name
        Component   = "Internal ALB ACM"
        ManagedBy   = "terraform-IaC"
      }
    }
    envoy-alb = {
      domain_name                                 = "api.${include.root.locals.deployment_tier}.${include.root.locals.region_code}.${values.base_domain}"
      subject_alternative_names                   = []
      zone_id                                     = dependency.route53.outputs.zone_ids["hyperswitch_public"]
      validation_method                           = "DNS"
      create_route53_records                      = true
      validate_certificate                        = true
      wait_for_validation                         = false
      validation_allow_overwrite_records          = false
      certificate_transparency_logging_preference = true
      tags = {
        Environment = include.root.locals.environment.full
        Project     = include.root.locals.project_name
        Component   = "Envoy ALB ACM"
        ManagedBy   = "terraform-IaC"
      }
    }
  }

  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }

}
