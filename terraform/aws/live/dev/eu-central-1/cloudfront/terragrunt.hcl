include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../..//modules/composition/cloudfront"
}

locals {
  base_tags = {
    Environment = "development"
    Project     = "hyperswitch"
    ManagedBy   = "terraform-IaC"
    Region      = "eu-central-1"
  }


  distributions = {
    for file in fileset("${get_terragrunt_dir()}/config/distributions/", "*.yaml") :
    trimsuffix(basename(file), ".yaml") => yamldecode(file("${get_terragrunt_dir()}/config/distributions/${file}"))
  }

  cloudfront_functions_list = [
    for file in fileset("${get_terragrunt_dir()}/config/functions/", "*.yaml") :
    yamldecode(file("${get_terragrunt_dir()}/config/functions/${file}"))
  ]
  cloudfront_functions = {
    for func in local.cloudfront_functions_list :
    func.name => func
  }

  origin_access_controls_list = yamldecode(file("${get_terragrunt_dir()}/config/origin_access_controls.yaml"))
  origin_access_controls = {
    for oac in local.origin_access_controls_list :
    oac.name => oac
  }

  cache_policies_list = [
    for file in fileset("${get_terragrunt_dir()}/config/policies/cache/", "*.yaml") :
    yamldecode(file("${get_terragrunt_dir()}/config/policies/cache/${file}"))
  ]
  cache_policies = {
    for policy in local.cache_policies_list :
    policy.name => policy
  }

  origin_request_policies_list = [
    for file in fileset("${get_terragrunt_dir()}/config/policies/origin_request/", "*.yaml") :
    yamldecode(file("${get_terragrunt_dir()}/config/policies/origin_request/${file}"))
  ]
  origin_request_policies = {
    for policy in local.origin_request_policies_list :
    policy.name => policy
  }

  response_headers_policies_list = [
    for file in fileset("${get_terragrunt_dir()}/config/policies/response_headers/", "*.yaml") :
    yamldecode(file("${get_terragrunt_dir()}/config/policies/response_headers/${file}"))
  ]
  response_headers_policies = {
    for policy in local.response_headers_policies_list :
    policy.name => policy
  }

  common_tags = merge(
    local.base_tags,
    {
      Environment = include.root.locals.environment.full
      ManagedBy   = "terraform"
    }
  )

  behavior_templates = {
    static_assets = {
      allowed_methods            = ["GET", "HEAD", "OPTIONS"]
      cached_methods             = ["GET", "HEAD"]
      viewer_protocol_policy     = "redirect-to-https"
      compress                   = true
      cache_policy_id            = "CachingOptimized"
      response_headers_policy_id = "SecurityHeadersPolicy"
      ttl = {
        min_ttl     = 86400
        default_ttl = 31536000
        max_ttl     = 31536000
      }
    }

    api = {
      allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods             = ["GET", "HEAD", "OPTIONS"]
      viewer_protocol_policy     = "redirect-to-https"
      compress                   = true
      cache_policy_id            = "CachingDisabled"
      response_headers_policy_id = "CORS-with-preflight-and-SecurityHeadersPolicy"
      ttl = {
        min_ttl     = 0
        default_ttl = 300
        max_ttl     = 3600
      }
    }

    admin = {
      allowed_methods            = ["GET", "HEAD", "OPTIONS"]
      cached_methods             = ["GET", "HEAD"]
      viewer_protocol_policy     = "redirect-to-https"
      compress                   = false
      cache_policy_id            = "CachingDisabled"
      response_headers_policy_id = "SecurityHeadersPolicy"
      ttl = {
        min_ttl     = 0
        default_ttl = 0
        max_ttl     = 0
      }
    }

    media = {
      allowed_methods            = ["GET", "HEAD", "OPTIONS"]
      cached_methods             = ["GET", "HEAD"]
      viewer_protocol_policy     = "redirect-to-https"
      compress                   = false
      cache_policy_id            = "CachingOptimized"
      response_headers_policy_id = "SecurityHeadersPolicy"
      ttl = {
        min_ttl     = 86400
        default_ttl = 86400
        max_ttl     = 31536000
      }
    }

    api_v2 = {
      allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods             = ["GET", "HEAD", "OPTIONS"]
      viewer_protocol_policy     = "redirect-to-https"
      compress                   = true
      cache_policy_id            = "CachingDisabled"
      response_headers_policy_id = "CORS-with-preflight-and-SecurityHeadersPolicy"
      ttl = {
        min_ttl     = 0
        default_ttl = 180
        max_ttl     = 1800
      }
    }
  }

  processed_distributions = {
    for dist_name, dist_config in local.distributions :
    dist_name => {
      comment             = lookup(dist_config, "comment", null)
      enabled             = lookup(dist_config, "enabled", true)
      default_root_object = lookup(dist_config, "default_root_object", "index.html")
      price_class         = lookup(dist_config, "price_class", "PriceClass_All")
      aliases             = lookup(dist_config, "aliases", [])
      viewer_certificate  = lookup(dist_config, "viewer_certificate", null)
      web_acl_id          = lookup(dist_config, "web_acl_id", null)

      origins = dist_config.origins

      default_cache_behavior = dist_config.default_cache_behavior

      ordered_cache_behaviors = [
        for behavior in lookup(dist_config, "ordered_cache_behaviors", []) :
        lookup(behavior, "template", null) != null ? merge(
          local.behavior_templates[behavior.template],
          {
            path_pattern               = behavior.path_pattern
            target_origin_id           = behavior.target_origin_id
            allowed_methods            = lookup(behavior, "allowed_methods", local.behavior_templates[behavior.template].allowed_methods)
            cached_methods             = lookup(behavior, "cached_methods", local.behavior_templates[behavior.template].cached_methods)
            viewer_protocol_policy     = lookup(behavior, "viewer_protocol_policy", local.behavior_templates[behavior.template].viewer_protocol_policy)
            compress                   = lookup(behavior, "compress", local.behavior_templates[behavior.template].compress)
            cache_policy_id            = lookup(behavior, "cache_policy_id", local.behavior_templates[behavior.template].cache_policy_id)
            origin_request_policy_id   = lookup(behavior, "origin_request_policy_id", null)
            response_headers_policy_id = lookup(behavior, "response_headers_policy_id", local.behavior_templates[behavior.template].response_headers_policy_id)
            ttl                        = lookup(behavior, "ttl", local.behavior_templates[behavior.template].ttl)
            lambda_function_associations = lookup(behavior, "lambda_function_associations", null) != null ? [
              for assoc in lookup(behavior, "lambda_function_associations", []) : assoc
            ] : []
            function_associations = lookup(behavior, "function_associations", null) != null ? [
              for assoc in lookup(behavior, "function_associations", []) : assoc
            ] : []
          }
          ) : {
          path_pattern               = behavior.path_pattern
          target_origin_id           = behavior.target_origin_id
          allowed_methods            = lookup(behavior, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
          cached_methods             = lookup(behavior, "cached_methods", ["GET", "HEAD"])
          viewer_protocol_policy     = lookup(behavior, "viewer_protocol_policy", "redirect-to-https")
          compress                   = lookup(behavior, "compress", true)
          cache_policy_id            = lookup(behavior, "cache_policy_id", null)
          origin_request_policy_id   = lookup(behavior, "origin_request_policy_id", null)
          response_headers_policy_id = lookup(behavior, "response_headers_policy_id", null)
          ttl                        = lookup(behavior, "ttl", null)
          lambda_function_associations = lookup(behavior, "lambda_function_associations", null) != null ? [
            for assoc in lookup(behavior, "lambda_function_associations", []) : assoc
          ] : []
          function_associations = lookup(behavior, "function_associations", null) != null ? [
            for assoc in lookup(behavior, "function_associations", []) : assoc
          ] : []
        }
      ]

      custom_error_responses = lookup(dist_config, "custom_error_responses", [])
      geo_restriction        = lookup(dist_config, "geo_restriction", {})
      invalidation           = lookup(dist_config, "invalidation", null)
    }
  }

  processed_origins = {
    for dist_name, dist_config in local.processed_distributions :
    dist_name => dist_config.origins
  }

  merged_behaviors = {
    for dist_name, dist_config in local.processed_distributions :
    dist_name => {
      ordered_cache_behaviors = dist_config.ordered_cache_behaviors
    }
  }

  transformed_response_headers_policies = {
    for key, policy in local.response_headers_policies : key => {
      name    = policy.name
      comment = try(policy.comment, null)
      cors_config = try(policy.cors_config, null) != null ? {
        access_control_allow_credentials = policy.cors_config.access_control_allow_credentials
        access_control_allow_headers     = try(policy.cors_config.access_control_allow_headers.items, policy.cors_config.access_control_allow_headers)
        access_control_allow_methods     = try(policy.cors_config.access_control_allow_methods.items, policy.cors_config.access_control_allow_methods)
        access_control_allow_origins     = try(policy.cors_config.access_control_allow_origins.items, policy.cors_config.access_control_allow_origins)
        access_control_expose_headers    = try(policy.cors_config.access_control_expose_headers.items, try(policy.cors_config.access_control_expose_headers, []))
        access_control_max_age_sec       = try(policy.cors_config.access_control_max_age_sec, null)
      } : null
      security_headers_config = can(policy.security_headers_config) ? policy.security_headers_config : null
    }
  }

  transformed_cache_policies          = local.cache_policies
  transformed_origin_request_policies = local.origin_request_policies
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  common_tags  = local.common_tags

  distributions = {
    for name, dist in local.processed_distributions :
    name => {
      origins                 = local.processed_origins[name]
      default_cache_behavior  = dist.default_cache_behavior
      ordered_cache_behaviors = local.merged_behaviors[name].ordered_cache_behaviors
      custom_error_responses  = dist.custom_error_responses
      default_root_object     = dist.default_root_object
      price_class             = dist.price_class
      enabled                 = dist.enabled
      comment                 = dist.comment
      web_acl_id              = dist.web_acl_id
      aliases                 = dist.aliases
      viewer_certificate      = dist.viewer_certificate
      geo_restriction         = dist.geo_restriction
      invalidation            = dist.invalidation
    }
  }

  enable_logging    = false
  create_log_bucket = false
  log_bucket_arn    = null
  log_prefix        = "cloudfront/"

  origin_access_controls = local.origin_access_controls

  cloudfront_functions = local.cloudfront_functions

  response_headers_policies = local.transformed_response_headers_policies
  cache_policies            = local.transformed_cache_policies
  origin_request_policies   = local.transformed_origin_request_policies
}
