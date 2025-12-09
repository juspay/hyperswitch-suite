# ============================================================================
# CloudFront Resources Module Locals
# ============================================================================

locals {
  create = var.create && (
    length(var.cloudfront_functions) > 0 ||
    length(var.response_headers_policies) > 0 ||
    length(var.cache_policies) > 0 ||
    length(var.origin_request_policies) > 0
  )

  tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    },
    var.common_tags
  )
}