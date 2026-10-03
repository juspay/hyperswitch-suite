output "managed_cache_policy_ids" {
  description = "Map of managed cache policy IDs by name"
  value       = { for k, v in data.aws_cloudfront_cache_policy.managed : k => v.id }
}

output "managed_origin_request_policy_ids" {
  description = "Map of managed origin request policy IDs by name"
  value       = { for k, v in data.aws_cloudfront_origin_request_policy.managed : k => v.id }
}

output "managed_response_headers_policy_ids" {
  description = "Map of managed response headers policy IDs by name"
  value       = { for k, v in data.aws_cloudfront_response_headers_policy.managed : k => v.id }
}

output "custom_cache_policy_ids" {
  description = "Map of custom cache policy IDs by key"
  value       = { for k, v in aws_cloudfront_cache_policy.custom : k => v.id }
}

output "custom_origin_request_policy_ids" {
  description = "Map of custom origin request policy IDs by key"
  value       = { for k, v in aws_cloudfront_origin_request_policy.custom : k => v.id }
}

output "custom_response_headers_policy_ids" {
  description = "Map of custom response headers policy IDs by key"
  value       = { for k, v in aws_cloudfront_response_headers_policy.custom : k => v.id }
}

output "all_cache_policy_ids" {
  description = "Combined map of managed and custom cache policy IDs"
  value = merge(
    { for k, v in data.aws_cloudfront_cache_policy.managed : k => v.id },
    { for k, v in aws_cloudfront_cache_policy.custom : k => v.id }
  )
}

output "all_origin_request_policy_ids" {
  description = "Combined map of managed and custom origin request policy IDs"
  value = merge(
    { for k, v in data.aws_cloudfront_origin_request_policy.managed : k => v.id },
    { for k, v in aws_cloudfront_origin_request_policy.custom : k => v.id }
  )
}

output "all_response_headers_policy_ids" {
  description = "Combined map of managed and custom response headers policy IDs"
  value = merge(
    { for k, v in data.aws_cloudfront_response_headers_policy.managed : k => v.id },
    { for k, v in aws_cloudfront_response_headers_policy.custom : k => v.id }
  )
}
