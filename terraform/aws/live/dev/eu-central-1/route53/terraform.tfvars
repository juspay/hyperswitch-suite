# ============================================================================
# Development Environment - EU Central 1 - Route53 Configuration
# ============================================================================
# This file contains configuration values for the Route53 DNS deployment
# Modify values as needed for your deployment
# ============================================================================

# ============================================================================
# Environment & Project Configuration
# ============================================================================
environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# ============================================================================
# Route53 Zones Configuration
# ============================================================================
# Define the DNS zones and records for the development environment.
# Uncomment and modify the example below to create your DNS zones.
#
# route53_zones = {
#   "hyperswitch_dev" = {
#     name    = "dev.hyperswitch.example.com"
#     comment = "Hyperswitch dev environment DNS zone"
#     tags = {
#       Environment = "dev"
#       Component   = "route53"
#     }
#     records = {
#       # Example A record pointing to an ALB
#       "app" = {
#         name = "app"
#         type = "A"
#         alias = {
#           name                   = "your-alb-dns-name.eu-central-1.elb.amazonaws.com"
#           zone_id                = "Z215JYRZR1TBD5"  # ELB hosted zone for eu-central-1
#           evaluate_target_health = true
#         }
#       }
#       # Example CNAME record
#       "api" = {
#         name    = "api"
#         type    = "CNAME"
#         ttl     = 300
#         records = ["app.dev.hyperswitch.example.com"]
#       }
#     }
#   }
# }

# Leave empty to create no zones (configure as needed)
route53_zones = {}

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  Component   = "route53"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
