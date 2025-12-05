# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {
  count = var.create ? 1 : 0
}

data "aws_region" "current" {
  count = var.create ? 1 : 0
}

data "aws_availability_zones" "available" {
  count = var.create ? 1 : 0
  state = "available"
}

# CloudFront managed cache policies
data "aws_cloudfront_cache_policy" "caching_optimized" {
  count = var.create ? 1 : 0
  name   = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  count = var.create ? 1 : 0
  name   = "Managed-CachingDisabled"
}

# Note: This policy doesn't exist in all regions
# data "aws_cloudfront_cache_policy" "caching_optimized_for_unmanaged_origins" {
#   count = var.create ? 1 : 0
#   name   = "Managed-CachingOptimizedForUnmanagedOrigins"
# }

# Note: This policy doesn't exist in all regions
# data "aws_cloudfront_cache_policy" "elemental_media_tailor" {
#   count = var.create ? 1 : 0
#   name   = "Managed-ElementalMediaTailor"
# }

# CloudFront managed origin request policies
data "aws_cloudfront_origin_request_policy" "all_viewer" {
  count = var.create ? 1 : 0
  name   = "Managed-AllViewer"
}

data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  count = var.create ? 1 : 0
  name   = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  count = var.create ? 1 : 0
  name   = "Managed-AllViewerExceptHostHeader"
}

# CloudFront managed response headers policies
data "aws_cloudfront_response_headers_policy" "security_headers_policy" {
  count = var.create ? 1 : 0
  name   = "Managed-SecurityHeadersPolicy"
}

data "aws_cloudfront_response_headers_policy" "cors_with_preflight_and_security_headers" {
  count = var.create ? 1 : 0
  name   = "Managed-CORS-with-preflight-and-SecurityHeadersPolicy"
}

data "aws_cloudfront_response_headers_policy" "simple_cors" {
  count = var.create ? 1 : 0
  name   = "Managed-SimpleCORS"
}