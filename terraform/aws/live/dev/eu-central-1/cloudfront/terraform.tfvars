# ============================================================================
# Example Terraform Variables
# ============================================================================
# Copy this file to terraform.tfvars and update with your actual values
# Note: CloudFront distributions, origins, OACs, response headers policies,
# and CloudFront functions are now managed via config.yaml

region      = "eu-central-1"
environment = "dev"
project_name = "hyperswitch"

# Common tags
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}

# ============================================================================
# Logging Configuration
# ============================================================================
# Choose ONE of the following options:

# Option 1: Use existing S3 bucket for logs
# enable_logging = true
# log_bucket_arn = "arn:aws:s3:::my-existing-cloudfront-logs-bucket"
# log_prefix = "cloudfront/dev/"

# Option 2: Create new S3 bucket for logs (auto-generated name)
# enable_logging = true
# create_log_bucket = true
# log_prefix = "cloudfront/"

# Option 3: Disable logging (CURRENT - for testing)
enable_logging = false
create_log_bucket = false
log_bucket_arn = null
log_prefix = "cloudfront/"

# Note: The following are now configured in config.yaml:
# - distributions: All CloudFront distributions with origins and cache behaviors
# - origin_access_controls: OAC configurations
# - response_headers_policies: CORS and security headers policies
# - cloudfront_functions: CloudFront Functions code and configuration
