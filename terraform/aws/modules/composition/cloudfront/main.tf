# ============================================================================
# CloudFront Module - Main Implementation (Updated)
# Uses cloudfront-resources module for shared resources
# ============================================================================

# Call cloudfront-resources module to create shared resources
module "cloudfront_resources" {
  source = "../../cloudfront-resources"

  create = var.create
  environment  = var.environment
  project_name = var.project_name
  common_tags  = var.common_tags

  cloudfront_functions = var.cloudfront_functions
  response_headers_policies = var.response_headers_policies
  cache_policies = var.cache_policies
  origin_request_policies = var.origin_request_policies
}

# Create S3 bucket for CloudFront logs if enabled and requested
module "log_bucket" {
  count = var.enable_logging && var.create_log_bucket ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  bucket = local.log_bucket_config.bucket_name
}

# Origin Access Controls
resource "aws_cloudfront_origin_access_control" "this" {
  for_each = local.create ? var.origin_access_controls : {}

  name                              = each.value.name
  description                       = each.value.description
  origin_access_control_origin_type = each.value.origin_access_control_origin_type
  signing_behavior                  = each.value.signing_behavior
  signing_protocol                  = each.value.signing_protocol
}

# CloudFront Distributions
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 6.0"

  for_each = var.distributions

  # Basic distribution configuration
  comment             = lookup(each.value, "comment", "${var.project_name}-${each.key}-${var.environment}")
  enabled             = lookup(each.value, "enabled", true)
  default_root_object = lookup(each.value, "default_root_object", "index.html")
  price_class         = lookup(each.value, "price_class", "PriceClass_All")
  is_ipv6_enabled     = true
  http_version        = "http2and3"

  # Origins configuration
  origin = {
    for idx, origin_config in local.processed_origins[each.key] :
    origin_config.origin_id => merge(
      {
        domain_name              = origin_config.resolved_domain_name
        origin_path              = lookup(origin_config, "origin_path", "")
        origin_access_control_id = lookup(origin_config, "origin_access_control_id", null)
        connection_attempts      = lookup(origin_config, "connection_attempts", 3)
        connection_timeout       = lookup(origin_config, "connection_timeout", 10)
      },
      origin_config.type != "s3" ? {
        custom_origin_config = {
          http_port                    = lookup(origin_config.custom_origin_config, "http_port", 80)
          https_port                   = lookup(origin_config.custom_origin_config, "https_port", 443)
          origin_protocol_policy       = lookup(origin_config.custom_origin_config, "origin_protocol_policy", "https-only")
          origin_ssl_protocols         = lookup(origin_config.custom_origin_config, "origin_ssl_protocols", ["TLSv1.2"])
          origin_keepalive_timeout     = lookup(origin_config.custom_origin_config, "origin_keepalive_timeout", 5)
          origin_read_timeout          = lookup(origin_config.custom_origin_config, "origin_read_timeout", 30)
        }
      } : {}
    )
  }

  # Default cache behavior
  default_cache_behavior = {
    target_origin_id       = local.processed_cache_behaviors[each.key].default.target_origin_id
    viewer_protocol_policy = local.processed_cache_behaviors[each.key].default.viewer_protocol_policy

    allowed_methods = local.processed_cache_behaviors[each.key].default.allowed_methods
    cached_methods  = local.processed_cache_behaviors[each.key].default.cached_methods
    compress        = local.processed_cache_behaviors[each.key].default.compress

    # Policy IDs - resolved in locals.tf to support custom, AWS managed (short/full names), ARNs, and UUIDs
    cache_policy_id            = local.processed_cache_behaviors[each.key].default.resolved_cache_policy_id
    origin_request_policy_id   = local.processed_cache_behaviors[each.key].default.resolved_origin_request_policy_id
    response_headers_policy_id = local.processed_cache_behaviors[each.key].default.resolved_response_headers_policy_id

    min_ttl     = local.processed_cache_behaviors[each.key].default.min_ttl
    default_ttl = local.processed_cache_behaviors[each.key].default.default_ttl
    max_ttl     = local.processed_cache_behaviors[each.key].default.max_ttl

    use_forwarded_values = false

    lambda_function_association = local.processed_cache_behaviors[each.key].default.lambda_function_associations
    function_association        = local.processed_cache_behaviors[each.key].default.function_associations
  }

  # Ordered cache behaviors
  ordered_cache_behavior = [
    for idx, behavior in local.processed_cache_behaviors[each.key].ordered : {
      path_pattern           = behavior.path_pattern
      target_origin_id       = behavior.target_origin_id
      viewer_protocol_policy = behavior.viewer_protocol_policy

      allowed_methods = behavior.allowed_methods
      cached_methods  = behavior.cached_methods
      compress        = behavior.compress

      # Policy IDs - resolved in locals.tf to support custom, AWS managed (short/full names), ARNs, and UUIDs
      cache_policy_id            = behavior.resolved_cache_policy_id
      origin_request_policy_id   = behavior.resolved_origin_request_policy_id
      response_headers_policy_id = behavior.resolved_response_headers_policy_id

      min_ttl     = behavior.min_ttl
      default_ttl = behavior.default_ttl
      max_ttl     = behavior.max_ttl

      use_forwarded_values = false

      lambda_function_association = behavior.lambda_function_associations
      function_association        = behavior.function_associations
    }
  ]

  # Logging configuration
  logging_config = var.enable_logging && local.log_bucket_config != null ? {
    bucket          = local.log_bucket_config.bucket_domain_name
    prefix          = lookup(local.log_bucket_config, "prefix", "cloudfront/")
    include_cookies = false
  } : null

  # Custom error responses
  custom_error_response = lookup(each.value, "custom_error_responses", [])

  # Geo restrictions (v6 uses restrictions block)
  restrictions = {
    geo_restriction = lookup(each.value, "geo_restriction", {
      restriction_type = "none"
      locations        = []
    })
  }

  # Web ACL
  web_acl_id = lookup(each.value, "web_acl_id", null)

  # Domain aliases
  aliases = lookup(each.value, "aliases", [])

  # Viewer certificate configuration
  # Note: When using cloudfront_default_certificate=true, AWS forces minimum_protocol_version to TLSv1
  # To enforce TLSv1.2+, you must use a custom ACM certificate.
  viewer_certificate = lookup(each.value, "viewer_certificate", null) != null ? {
    acm_certificate_arn      = each.value.viewer_certificate.acm_certificate_arn
    ssl_support_method       = lookup(each.value.viewer_certificate, "ssl_support_method", "sni-only")
    minimum_protocol_version = lookup(each.value.viewer_certificate, "minimum_protocol_version", "TLSv1.2_2021")
    cloudfront_default_certificate = false
  } : {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"  # AWS enforces TLSv1 for default certificate
  }

  origin_access_control = {}

  # Add distribution-specific name to tags
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${each.key}-${var.environment}"
    }
  )
}
# ============================================================================
# S3 Bucket Policies for OAC
# ============================================================================

# Manage bucket policies using null_resource and AWS CLI for granular control
# This approach allows us to add/remove individual statements without destroying the entire policy
# Key feature: Only removes the EXACT statements added by this Terraform configuration
resource "null_resource" "s3_bucket_policy_manager" {
  for_each = local.create ? local.bucket_policy_map : {}

  triggers = {
    bucket_id     = each.key
    policy_hash   = md5(jsonencode(each.value))
    existing_hash = md5(jsonencode(local.get_existing_statements[each.key]))
    # Store the exact Sid list for statements managed by THIS configuration
    # This ensures we only remove OUR statements on destroy, not others
    managed_sids  = jsonencode([for stmt in each.value : stmt.Sid])
  }

  # Apply the merged policy (existing + CloudFront statements)
  provisioner "local-exec" {
    command = <<-EOT
      # Build the complete policy JSON
      POLICY=$(cat <<'POLICY_EOF'
${jsonencode({
  Version = "2012-10-17"
  Statement = concat(
    local.get_existing_statements[each.key],
    each.value
  )
})}
POLICY_EOF
)
      
      # Apply the policy to the bucket
      echo "$POLICY" | aws s3api put-bucket-policy --bucket ${each.key} --policy file:///dev/stdin
    EOT
  }

  # On destroy, remove ONLY the specific statements added by this Terraform configuration
  # Preserves statements from other distributions and external configurations
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Get current policy
      CURRENT_POLICY=$(aws s3api get-bucket-policy --bucket ${self.triggers.bucket_id} --query Policy --output text 2>/dev/null || echo "")
      
      if [ -n "$CURRENT_POLICY" ]; then
        # Parse the list of Sids that this configuration manages
        MANAGED_SIDS='${self.triggers.managed_sids}'
        
        # Remove ONLY the statements with Sids in our managed list
        # This preserves statements from other distributions and external configurations
        FILTERED_POLICY=$(echo "$CURRENT_POLICY" | jq --argjson sids "$MANAGED_SIDS" '
          .Statement |= map(select(.Sid as $sid | $sids | index($sid) | not))
        ')
        
        # Count remaining statements
        STATEMENT_COUNT=$(echo "$FILTERED_POLICY" | jq '.Statement | length')
        
        # If no statements remain, delete the policy entirely
        if [ "$STATEMENT_COUNT" -eq 0 ]; then
          echo "No statements remain, deleting bucket policy"
          aws s3api delete-bucket-policy --bucket ${self.triggers.bucket_id} 2>/dev/null || true
        else
          # Otherwise, update with filtered policy (preserving other statements)
          echo "Removing only managed CloudFront statements, preserving others"
          echo "$FILTERED_POLICY" | aws s3api put-bucket-policy --bucket ${self.triggers.bucket_id} --policy file:///dev/stdin
        fi
      fi
    EOT
    
    on_failure = continue
  }

  depends_on = [module.cloudfront]
}

# ============================================================================
# CloudFront Invalidation
# ============================================================================

resource "null_resource" "cloudfront_invalidation" {
  for_each = local.create ? {
    for dist_name, dist_config in var.distributions :
    dist_name => dist_config
    if lookup(dist_config, "invalidation", null) != null && lookup(lookup(dist_config, "invalidation", {}), "enabled", false)
  } : {}

  triggers = {
    distribution_id = module.cloudfront[each.key].cloudfront_distribution_id
    version         = each.value.invalidation.version
    paths           = join(",", each.value.invalidation.paths)
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws cloudfront create-invalidation \
        --distribution-id ${module.cloudfront[each.key].cloudfront_distribution_id} \
        --paths ${join(" ", each.value.invalidation.paths)}
    EOT
  }

  depends_on = [module.cloudfront]
}