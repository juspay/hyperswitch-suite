# ============================================================================
# Development Environment - EU Central 1 - Load Balancer Configuration
# ============================================================================
# This file contains configuration values for the Application Load Balancer
# Modify values as needed for your deployment
# ============================================================================

# ============================================================================
# Environment & Project Configuration
# ============================================================================
environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# ============================================================================
# Load Balancer Configuration
# ============================================================================
create_alb = true

# Custom name for the ALB (auto-generated if not set)
# name = "dev-hyperswitch-alb"

# Set to true for internal (private) load balancer, false for internet-facing
internal = false

# TODO: Replace with your actual VPC ID
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"  # Replace with your VPC ID

# TODO: Replace with your actual public subnet IDs for the ALB
# Use public subnets for internet-facing ALB, private subnets for internal ALB
subnets = [
  "subnet-xxxxxxxxxxxxxxxxx",  # Replace with your subnet ID (AZ-a)
  "subnet-xxxxxxxxxxxxxxxxx",  # Replace with your subnet ID (AZ-b)
  "subnet-xxxxxxxxxxxxxxxxx",  # Replace with your subnet ID (AZ-c)
]

# ============================================================================
# ALB Settings
# ============================================================================
enable_deletion_protection       = false  # Set to true for production
enable_cross_zone_load_balancing = true
enable_http2                     = true
enable_waf_fail_open             = false
drop_invalid_header_fields       = false
idle_timeout                     = 60

# ============================================================================
# Security Group Rules
# ============================================================================
ingress_rules = {
  "http" = {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic"
  }
  "https" = {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic"
  }
}

egress_rules = {}

# ============================================================================
# Listeners Configuration
# ============================================================================
# Default: HTTP listener with a fixed response
# Uncomment and modify to add HTTPS listener with certificate
listeners = {
  "http" = {
    port                = 80
    protocol            = "HTTP"
    default_action_type = "fixed-response"
    fixed_response_config = {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }
  # Uncomment to add HTTPS listener (requires ACM certificate)
  # "https" = {
  #   port                = 443
  #   protocol            = "HTTPS"
  #   ssl_policy          = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  #   certificate_arn     = "arn:aws:acm:eu-central-1:XXXXXXXXXXXX:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  #   default_action_type = "fixed-response"
  #   fixed_response_config = {
  #     content_type = "text/plain"
  #     message_body = "OK"
  #     status_code  = "200"
  #   }
  # }
}

# ============================================================================
# Route53 Configuration
# ============================================================================
# Optional: Create or associate a Route53 hosted zone with this ALB
route53_zone = {
  create = false
  # To use an existing zone, provide the zone_id:
  # zone_id = "ZXXXXXXXXXXXXXXXXX"
  # To create a new zone:
  # create = true
  # name   = "dev.hyperswitch.example.com"
}

# Optional: Create Route53 DNS records pointing to this ALB
route53_records = {}
# Example:
# route53_records = {
#   "app" = {
#     name            = "app"
#     type            = "A"
#     create_as_alias = true
#   }
# }

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  Component   = "load-balancer"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
