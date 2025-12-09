# ============================================================================
# CloudFront Resources Module Outputs
# ============================================================================

# CloudFront Functions
output "cloudfront_functions" {
  description = "Map of CloudFront Functions"
  value = local.create ? {
    for fn in aws_cloudfront_function.this :
    fn.name => {
      id     = fn.id
      name   = fn.name
      arn    = fn.arn
      etag   = fn.etag
      status = fn.status
    }
  } : {}
}

output "cloudfront_function_ids" {
  description = "Map of CloudFront Function IDs"
  value = local.create ? {
    for fn in aws_cloudfront_function.this :
    fn.name => fn.id
  } : {}
}

output "cloudfront_function_arns" {
  description = "Map of CloudFront Function ARNs"
  value = local.create ? {
    for fn in aws_cloudfront_function.this :
    fn.name => fn.arn
  } : {}
}

output "cloudfront_function_names" {
  description = "List of CloudFront Function names"
  value = local.create ? aws_cloudfront_function.this[*].name : []
}

# Response Headers Policies
output "response_headers_policies" {
  description = "Map of Response Headers Policies"
  value = local.create ? {
    for policy in aws_cloudfront_response_headers_policy.this :
    policy.name => {
      id   = policy.id
      name = policy.name
      arn  = policy.arn
    }
  } : {}
}

output "response_headers_policy_ids" {
  description = "Map of Response Headers Policy IDs"
  value = local.create ? {
    for policy in aws_cloudfront_response_headers_policy.this :
    policy.name => policy.id
  } : {}
}

output "response_headers_policy_arns" {
  description = "Map of Response Headers Policy ARNs"
  value = local.create ? {
    for policy in aws_cloudfront_response_headers_policy.this :
    policy.name => policy.arn
  } : {}
}

# Cache Policies
output "cache_policies" {
  description = "Map of Cache Policies"
  value = local.create ? {
    for policy in aws_cloudfront_cache_policy.this :
    policy.name => {
      id   = policy.id
      name = policy.name
      arn  = policy.arn
    }
  } : {}
}

output "cache_policy_ids" {
  description = "Map of Cache Policy IDs"
  value = local.create ? {
    for policy in aws_cloudfront_cache_policy.this :
    policy.name => policy.id
  } : {}
}

# Origin Request Policies
output "origin_request_policies" {
  description = "Map of Origin Request Policies"
  value = local.create ? {
    for policy in aws_cloudfront_origin_request_policy.this :
    policy.name => {
      id   = policy.id
      name = policy.name
      arn  = policy.arn
    }
  } : {}
}

output "origin_request_policy_ids" {
  description = "Map of Origin Request Policy IDs"
  value = local.create ? {
    for policy in aws_cloudfront_origin_request_policy.this :
    policy.name => policy.id
  } : {}
}