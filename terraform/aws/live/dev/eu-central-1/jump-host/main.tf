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
  public_subnet_id  = var.public_subnet_id
  private_subnet_id = var.private_subnet_id

  # Instance Configuration
  external_jump_ami_id = var.external_jump_ami_id
  internal_jump_ami_id = var.internal_jump_ami_id
  instance_type        = var.instance_type
  root_volume_size     = var.root_volume_size
  root_volume_type     = var.root_volume_type

  # Logging Configuration
  log_retention_days = var.log_retention_days

  # Migration Mode Configuration
  enable_migration_mode = var.enable_migration_mode

  # Security Group Rules Configuration
  external_jump_ingress_rules = var.external_jump_ingress_rules
  external_jump_egress_rules  = var.external_jump_egress_rules
  internal_jump_egress_rules  = var.internal_jump_egress_rules

  # Tags
  tags = var.common_tags
}
