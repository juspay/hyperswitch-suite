# ============================================================================
# ECR Configuration - Dev Environment
# ============================================================================

# General Configuration
environment  = "dev"
project_name = "hyperswitch"
region       = "eu-central-1"

# ECR Repositories
repositories = {
  hyperswitch-app = {
    name                 = "dev-hyperswitch-app"
    image_tag_mutability = "MUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
    force_delete         = false
  }

  hyperswitch-web = {
    name                 = "dev-hyperswitch-web"
    image_tag_mutability = "MUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
    force_delete         = false
  }

  hyperswitch-control-center = {
    name                 = "dev-hyperswitch-control-center"
    image_tag_mutability = "MUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
    force_delete         = false
  }
}

# Tags
tags = {
  ManagedBy   = "terraform"
  Environment = "dev"
  Project     = "hyperswitch"
}
