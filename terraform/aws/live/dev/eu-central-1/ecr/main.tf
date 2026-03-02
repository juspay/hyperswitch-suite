# ============================================================================
# ECR (Elastic Container Registry) Deployment - Dev Environment
# ============================================================================
# This configuration deploys AWS ECR repositories for container images:
#   - Multiple repositories for different services
#   - Image scanning on push enabled
#   - Encryption at rest using AES256 or KMS
#   - Configurable image tag mutability
#
# Security: Encryption at rest, image scanning
# Management: Automated via Terraform
# ============================================================================

provider "aws" {
  region = var.region
}

# ECR Module
module "ecr" {
  source = "../../../../modules/composition/ecr"

  # Environment Configuration
  environment  = var.environment
  project_name = var.project_name

  # ECR Repositories
  repositories = var.repositories

  # Tags
  tags = var.tags
}
