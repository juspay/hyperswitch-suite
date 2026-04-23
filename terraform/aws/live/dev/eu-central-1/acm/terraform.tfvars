# ============================================================================
# Development Environment - EU Central 1 - ACM Configuration
# ============================================================================
# This file contains configuration values for ACM SSL/TLS certificates
# Modify values as needed for your deployment
# ============================================================================

# ============================================================================
# Environment & Project Configuration
# ============================================================================
environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# ============================================================================
# Certificate Configuration
# ============================================================================
# Define SSL/TLS certificates for the development environment.
# Uncomment and modify the example below to create your certificates.
#
# certificates = {
#   "main" = {
#     domain_name               = "dev.hyperswitch.example.com"
#     subject_alternative_names = ["*.dev.hyperswitch.example.com"]
#     # Provide the Route53 hosted zone ID for automatic DNS validation
#     # TODO: Replace with your Route53 zone ID
#     zone_id                = "ZXXXXXXXXXXXXXXXXX"  # Replace with your Route53 zone ID
#     validation_method      = "DNS"
#     create_route53_records = true
#     validate_certificate   = true
#     wait_for_validation    = true
#     tags = {
#       Component = "main-cert"
#     }
#   }
#   "api" = {
#     domain_name               = "api.dev.hyperswitch.example.com"
#     subject_alternative_names = []
#     zone_id                   = "ZXXXXXXXXXXXXXXXXX"  # Replace with your Route53 zone ID
#     validation_method         = "DNS"
#     create_route53_records    = true
#     validate_certificate      = true
#     wait_for_validation       = true
#   }
# }

# Leave empty to create no certificates (configure as needed)
certificates = {}

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  Component   = "acm"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
