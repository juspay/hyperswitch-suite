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

# CloudFront managed policies - Dynamically fetched based on usage
# Collect all unique policy names that might be AWS managed policies
locals {
  # Extract all policy references from the configuration (both default and ordered cache behaviors)
  all_cache_policy_names = distinct(flatten([
    for dist in var.distributions : concat(
      # Default cache behavior
      lookup(dist.default_cache_behavior, "cache_policy_id", null) != null ? [dist.default_cache_behavior.cache_policy_id] : [],
      # Ordered cache behaviors
      [
        for behavior in lookup(dist, "ordered_cache_behaviors", []) :
        behavior.cache_policy_id
        if lookup(behavior, "cache_policy_id", null) != null
      ]
    )
  ]))

  all_origin_request_policy_names = distinct(flatten([
    for dist in var.distributions : concat(
      # Default cache behavior
      lookup(dist.default_cache_behavior, "origin_request_policy_id", null) != null ? [dist.default_cache_behavior.origin_request_policy_id] : [],
      # Ordered cache behaviors
      [
        for behavior in lookup(dist, "ordered_cache_behaviors", []) :
        behavior.origin_request_policy_id
        if lookup(behavior, "origin_request_policy_id", null) != null
      ]
    )
  ]))

  all_response_headers_policy_names = distinct(flatten([
    for dist in var.distributions : concat(
      # Default cache behavior
      lookup(dist.default_cache_behavior, "response_headers_policy_id", null) != null ? [dist.default_cache_behavior.response_headers_policy_id] : [],
      # Ordered cache behaviors
      [
        for behavior in lookup(dist, "ordered_cache_behaviors", []) :
        behavior.response_headers_policy_id
        if lookup(behavior, "response_headers_policy_id", null) != null
      ]
    )
  ]))

  # Filter for only policies that look like AWS managed (not ARNs, not UUIDs, not custom)
  aws_managed_cache_policy_names = [
    for name in local.all_cache_policy_names :
    name == null ? null : (
      startswith(name, "arn:") ? null :
      can(regex("^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$", name)) ? null :
      contains(keys(module.cloudfront_resources.cache_policy_ids), name) ? null :
      startswith(name, "Managed-") ? name :
      "Managed-${name}"
    )
  ]

  aws_managed_origin_request_policy_names = [
    for name in local.all_origin_request_policy_names :
    name == null ? null : (
      startswith(name, "arn:") ? null :
      can(regex("^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$", name)) ? null :
      contains(keys(module.cloudfront_resources.origin_request_policy_ids), name) ? null :
      startswith(name, "Managed-") ? name :
      "Managed-${name}"
    )
  ]

  aws_managed_response_headers_policy_names = [
    for name in local.all_response_headers_policy_names :
    name == null ? null : (
      startswith(name, "arn:") ? null :
      can(regex("^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$", name)) ? null :
      contains(keys(module.cloudfront_resources.response_headers_policy_ids), name) ? null :
      startswith(name, "Managed-") ? name :
      "Managed-${name}"
    )
  ]
}

# Dynamic data sources for cache policies
data "aws_cloudfront_cache_policy" "aws_managed" {
  count = local.create ? length(compact(local.aws_managed_cache_policy_names)) : 0
  name   = compact(local.aws_managed_cache_policy_names)[count.index]
}

# Dynamic data sources for origin request policies
data "aws_cloudfront_origin_request_policy" "aws_managed" {
  count = local.create ? length(compact(local.aws_managed_origin_request_policy_names)) : 0
  name   = compact(local.aws_managed_origin_request_policy_names)[count.index]
}

# Dynamic data sources for response headers policies
data "aws_cloudfront_response_headers_policy" "aws_managed" {
  count = local.create ? length(compact(local.aws_managed_response_headers_policy_names)) : 0
  name   = compact(local.aws_managed_response_headers_policy_names)[count.index]
}

# ============================================================================
# S3 Bucket Policies for OAC
# ============================================================================

# Read existing S3 bucket policies to preserve statements from other CloudFront distributions
data "aws_s3_bucket_policy" "existing" {
  for_each = local.create ? toset([
    for dist_name, origins in local.s3_bucket_origins :
    origins[0].bucket_id if length(origins) > 0
  ]) : []

  bucket = each.value
}