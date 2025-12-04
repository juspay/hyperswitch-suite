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

# Logging configuration
# Option 1: Let Terraform auto-create the bucket (RECOMMENDED for testing)
enable_logging = false 
create_log_bucket = false
# Comment out log_bucket to let Terraform auto-generate the bucket name
# log_bucket = {
#   bucket_name = "hyperswitch-cloudfront-logs-dev-eu-central-1"
#   bucket_arn = "arn:aws:s3:::hyperswitch-cloudfront-logs-dev-eu-central-1"
#   bucket_domain_name = "hyperswitch-cloudfront-logs-dev-eu-central-1.s3.eu-central-1.amazonaws.com"
#   prefix = "cloudfront/"
# }

# Option 2: Disable logging temporarily for testing
# enable_logging = false
# create_log_bucket = false

# Note: The following are now configured in config.yaml:
# - distributions: All CloudFront distributions with origins and cache behaviors
# - origin_access_controls: OAC configurations
# - response_headers_policies: CORS and security headers policies
# - cloudfront_functions: CloudFront Functions code and configuration
