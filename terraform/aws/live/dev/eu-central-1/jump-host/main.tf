# ============================================================================
# Jump Host Deployment - Dev Environment
# ============================================================================
# This configuration deploys two EC2 jump hosts:
#   - External Jump: Public subnet with public IP (accessible via Session Manager)
#   - Internal Jump: Private subnet (accessible only from external jump via SSH)
#
# Access Method: AWS Systems Manager Session Manager (no SSH keys required)
# Authentication: IAM-based access control
# Logging: All sessions and system logs sent to CloudWatch
# ============================================================================

provider "aws" {
  region = var.region
}

# Jump Host Module
module "jump_host" {
  source = "../../../../modules/composition/jump-host"

  environment  = var.environment
  project_name = var.project_name

  # Network Configuration
  vpc_id            = var.vpc_id
  vpc_cidr          = var.vpc_cidr
  public_subnet_id  = var.public_subnet_id
  private_subnet_id = var.private_subnet_id

  # Instance Configuration
  ami_id         = var.ami_id
  instance_type  = var.instance_type
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  # Logging Configuration
  log_retention_days = var.log_retention_days

  # Tags
  tags = var.common_tags
}
