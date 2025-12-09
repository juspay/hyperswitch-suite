# ============================================================================
# Outputs
# ============================================================================

# CloudFront Distributions
output "distributions" {
  description = "Map of CloudFront distributions"
  value = local.create ? {
    for name, dist_module in module.cloudfront :
    name => {
      id                   = dist_module.cloudfront_distribution_id
      arn                  = dist_module.cloudfront_distribution_arn
      domain_name          = dist_module.cloudfront_distribution_domain_name
      hosted_zone_id       = dist_module.cloudfront_distribution_hosted_zone_id
      status               = dist_module.cloudfront_distribution_status
    }
  } : {}
}

# Distribution IDs
output "distribution_ids" {
  description = "Map of CloudFront distribution IDs"
  value = local.create ? {
    for name, dist_module in module.cloudfront :
    name => dist_module.cloudfront_distribution_id
  } : {}
}

# Distribution ARNs
output "distribution_arns" {
  description = "Map of CloudFront distribution ARNs"
  value = local.create ? {
    for name, dist_module in module.cloudfront :
    name => dist_module.cloudfront_distribution_arn
  } : {}
}

# Distribution Domain Names
output "distribution_domain_names" {
  description = "Map of CloudFront distribution domain names"
  value = local.create ? {
    for name, dist_module in module.cloudfront :
    name => dist_module.cloudfront_distribution_domain_name
  } : {}
}

# Distribution Hosted Zone IDs
output "distribution_hosted_zone_ids" {
  description = "Map of CloudFront distribution hosted zone IDs"
  value = local.create ? {
    for name, dist_module in module.cloudfront :
    name => dist_module.cloudfront_distribution_hosted_zone_id
  } : {}
}

# Distribution Status
output "distribution_statuses" {
  description = "Map of CloudFront distribution statuses"
  value = local.create ? {
    for name, dist_module in module.cloudfront :
    name => dist_module.cloudfront_distribution_status
  } : {}
}

# CloudFront Functions
output "cloudfront_functions" {
  description = "Map of CloudFront Functions"
  value       = module.cloudfront_resources.cloudfront_functions
}

# CloudFront Function IDs
output "cloudfront_function_ids" {
  description = "Map of CloudFront Function IDs"
  value       = module.cloudfront_resources.cloudfront_function_ids
}

# CloudFront Function ARNs
output "cloudfront_function_arns" {
  description = "Map of CloudFront Function ARNs"
  value       = module.cloudfront_resources.cloudfront_function_arns
}

# Origin Access Controls
output "origin_access_controls" {
  description = "Map of Origin Access Control resources"
  value = local.create ? {
    for oac in aws_cloudfront_origin_access_control.this :
    oac.name => {
      id   = oac.id
      name = oac.name
      arn  = oac.arn
    }
  } : {}
}

# Origin Access Control IDs
output "origin_access_control_ids" {
  description = "Map of Origin Access Control IDs"
  value = local.create ? {
    for oac in aws_cloudfront_origin_access_control.this :
    oac.name => oac.id
  } : {}
}

# Origin Access Control ARNs
output "origin_access_control_arns" {
  description = "Map of Origin Access Control ARNs"
  value = local.create ? {
    for oac in aws_cloudfront_origin_access_control.this :
    oac.name => oac.arn
  } : {}
}

# Response Headers Policies
output "response_headers_policies" {
  description = "Map of Response Headers Policies"
  value       = module.cloudfront_resources.response_headers_policies
}

# Response Headers Policy IDs
output "response_headers_policy_ids" {
  description = "Map of Response Headers Policy IDs"
  value       = module.cloudfront_resources.response_headers_policy_ids
}

# Response Headers Policy ARNs
output "response_headers_policy_arns" {
  description = "Map of Response Headers Policy ARNs"
  value       = module.cloudfront_resources.response_headers_policy_arns
}

# Log Bucket
output "log_bucket" {
  description = "S3 bucket for CloudFront access logs"
  value = var.enable_logging && local.log_bucket_config != null ? local.log_bucket_config : null
}

# Log Bucket Name
output "log_bucket_name" {
  description = "Name of S3 bucket for CloudFront access logs"
  value = var.enable_logging && local.log_bucket_config != null ? local.log_bucket_config.bucket_name : null
}

# Log Bucket ARN
output "log_bucket_arn" {
  description = "ARN of S3 bucket for CloudFront access logs"
  value = var.enable_logging && local.log_bucket_config != null ? local.log_bucket_config.bucket_arn : null
}

# Log Bucket Domain Name
output "log_bucket_domain_name" {
  description = "Domain name of S3 bucket for CloudFront access logs"
  value = var.enable_logging && local.log_bucket_config != null ? local.log_bucket_config.bucket_domain_name : null
}

# Invalidation Commands
output "invalidation_commands" {
  description = "Commands to manually invalidate CloudFront caches"
  value = local.create ? {
    for name, dist_module in module.cloudfront :
    name => lookup(var.distributions[name], "invalidation", null) != null && lookup(var.distributions[name].invalidation, "enabled", false) ? "aws cloudfront create-invalidation --distribution-id ${dist_module.cloudfront_distribution_id} --paths '${join(" ", var.distributions[name].invalidation.paths)}'" : null
  } : {}
}

# CloudFront Configuration Summary
output "configuration_summary" {
  description = "Summary of CloudFront configuration"
  value = local.create ? {
    distributions_count      = length(var.distributions)
    total_origins           = sum([for dist in var.distributions : length(dist.origins)])
    total_cache_behaviors   = sum([for dist in var.distributions : length(dist.ordered_cache_behaviors)])
    cloudfront_functions    = length(var.cloudfront_functions)
    origin_access_controls  = length(var.origin_access_controls)
    response_headers_policies = length(var.response_headers_policies)
    invalidations_enabled  = length([for name, dist in var.distributions : name if try(dist.invalidation.enabled, false)])
    logging_enabled        = var.enable_logging
    environment            = var.environment
    project_name           = var.project_name
  } : {}
}