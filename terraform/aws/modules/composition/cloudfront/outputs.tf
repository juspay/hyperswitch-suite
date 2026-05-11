# ============================================================================
# Outputs
# ============================================================================

# CloudFront Distributions
output "distributions" {
  description = "Map of CloudFront distributions"
  value = local.create ? {
    for name, dist_module in module.cloudfront :
    name => {
      id             = dist_module.cloudfront_distribution_id
      arn            = dist_module.cloudfront_distribution_arn
      domain_name    = dist_module.cloudfront_distribution_domain_name
      hosted_zone_id = dist_module.cloudfront_distribution_hosted_zone_id
      status         = dist_module.cloudfront_distribution_status
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
  value       = aws_cloudfront_function.this
}

# CloudFront Function IDs
output "cloudfront_function_ids" {
  description = "Map of CloudFront Function IDs"
  value       = { for k, v in aws_cloudfront_function.this : k => v.id }
}

# CloudFront Function ARNs
output "cloudfront_function_arns" {
  description = "Map of CloudFront Function ARNs"
  value       = { for k, v in aws_cloudfront_function.this : k => v.arn }
}

output "origin_access_identities" {
  description = "Map of Origin Access Identity resources"
  value = local.create ? {
    for name, dist_module in module.cloudfront :
    name => dist_module.cloudfront_origin_access_identities
  } : {}
}

# Origin Access Identity IDs
output "origin_access_identity_ids" {
  description = "Map of Origin Access Identity IDs"
  value = local.create ? {
    for name, dist_module in module.cloudfront :
    name => dist_module.cloudfront_origin_access_identity_ids
  } : {}
}

# Origin Access Identity IAM ARNs
output "origin_access_identity_iam_arns" {
  description = "Map of Origin Access Identity IAM ARNs"
  value = local.create ? {
    for name, dist_module in module.cloudfront :
    name => dist_module.cloudfront_origin_access_identity_iam_arns
  } : {}
}

# Response Headers Policies
output "response_headers_policies" {
  description = "Map of Response Headers Policies"
  value       = aws_cloudfront_response_headers_policy.this
}

# Response Headers Policy IDs
output "response_headers_policy_ids" {
  description = "Map of Response Headers Policy IDs"
  value       = { for k, v in aws_cloudfront_response_headers_policy.this : k => v.id }
}

# Response Headers Policy ARNs
output "response_headers_policy_arns" {
  description = "Map of Response Headers Policy ARNs"
  value       = { for k, v in aws_cloudfront_response_headers_policy.this : k => v.arn }
}

# Cache Policies
output "cache_policies" {
  description = "Map of Cache Policies"
  value       = aws_cloudfront_cache_policy.this
}

# Cache Policy IDs
output "cache_policy_ids" {
  description = "Map of Cache Policy IDs"
  value       = { for k, v in aws_cloudfront_cache_policy.this : k => v.id }
}

# Origin Request Policies
output "origin_request_policies" {
  description = "Map of Origin Request Policies"
  value       = aws_cloudfront_origin_request_policy.this
}

# Origin Request Policy IDs
output "origin_request_policy_ids" {
  description = "Map of Origin Request Policy IDs"
  value       = { for k, v in aws_cloudfront_origin_request_policy.this : k => v.id }
}

# Log Bucket
output "log_bucket" {
  description = "S3 bucket for CloudFront access logs"
  value       = var.enable_logging && local.log_bucket_config != null ? local.log_bucket_config : null
}

# Log Bucket Name
output "log_bucket_name" {
  description = "Name of S3 bucket for CloudFront access logs"
  value       = var.enable_logging && local.log_bucket_config != null ? local.log_bucket_config.bucket_name : null
}

# Log Bucket ARN
output "log_bucket_arn" {
  description = "ARN of S3 bucket for CloudFront access logs"
  value       = var.enable_logging && local.log_bucket_config != null ? local.log_bucket_config.bucket_arn : null
}

# Log Bucket Domain Name
output "log_bucket_domain_name" {
  description = "Domain name of S3 bucket for CloudFront access logs"
  value       = var.enable_logging && local.log_bucket_config != null ? local.log_bucket_config.bucket_domain_name : null
}


# CloudFront Configuration Summary
output "configuration_summary" {
  description = "Summary of CloudFront configuration"
  value = local.create ? {
    distributions_count       = length(local.all_distributions)
    total_origins             = sum([for dist in local.all_distributions : length(dist.origins)])
    total_cache_behaviors     = sum([for dist in local.all_distributions : length(dist.ordered_cache_behaviors)])
    cloudfront_functions      = length(var.cloudfront_functions)
    origin_access_identities  = sum([for dist in module.cloudfront : length(dist.cloudfront_origin_access_identities)])
    response_headers_policies = length(var.response_headers_policies)
    invalidations_enabled     = length([for name, dist in local.all_distributions : name if try(dist.invalidation.enabled, false)])
    logging_enabled           = var.enable_logging
    environment               = var.environment
    project_name              = var.project_name
  } : {}
}