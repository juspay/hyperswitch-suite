# ============================================================================
# Locker Deployment - Dev Environment
# ============================================================================
# This configuration deploys the Hyperswitch Locker card vault service:
#   - EC2 instance running locker application
#   - Network Load Balancer for internal access
#   - Security groups with least-privilege access
#   - IAM roles with permissions for ECR, S3, KMS, and CloudWatch
#
# Access Method: Via Network Load Balancer from jump host
# Authentication: SSH via jump host (emergency access only)
# Logging: All system logs and application logs sent to CloudWatch
# ============================================================================

provider "aws" {
  region = var.region
}

# Locker Module
module "locker" {
  source = "../../../../modules/composition/locker"

  environment  = var.environment
  project_name = var.project_name

  # Network Configuration
  vpc_id                = var.vpc_id
  locker_subnet_id      = var.locker_subnet_id
  rds_security_group_id = var.rds_security_group_id

  # Instance Configuration
  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Security Configuration
  jump_host_security_group_id = var.jump_host_security_group_id

  # Logging Configuration
  log_retention_days = var.log_retention_days

  # Tags
  tags = var.common_tags
}
