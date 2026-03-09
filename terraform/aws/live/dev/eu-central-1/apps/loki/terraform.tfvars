# Common tags
common_tags = {
  Project     = "hyperswitch"
  Environment = "dev"
  ManagedBy   = "terraform"
}

# OIDC Provider Configuration
# Replace with your EKS cluster's OIDC provider ARN
oidc_provider_arn = "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# ============================================================================
# S3 Bucket Configuration for Loki Logs
# ============================================================================

# Set to true to create S3 bucket for Loki logs storage
create_s3_bucket = true

# Optional: Custom bucket name (if null, auto-generated as hs-{env}-loki-logs-storage)
# s3_bucket_name = "hs-dev-loki-logs-storage"

# Optional: Force destroy bucket with objects (use with caution in non-prod)
# s3_force_destroy = true

# Optional: Enable versioning
# s3_enable_versioning = false

# Optional: Server access logging configuration
# s3_server_access_logging = {
#   enabled       = true
#   target_bucket = "hs-dev-s3-server-access-logs"
#   target_prefix = ""  # Auto-generated if empty: {account}/{region}/{bucket}/
# }

# Optional: Lifecycle rules (e.g., expire logs after 90 days)
# See terraform-aws-modules/s3-bucket documentation for full options
# s3_lifecycle_rules = [
#   {
#     id      = "expire-old-logs"
#     enabled = true
#     expiration = {
#       days = 90
#     }
#   }
# ]
