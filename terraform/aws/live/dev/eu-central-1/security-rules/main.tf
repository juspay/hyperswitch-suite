# ============================================================================
# Security Rules Deployment - Dev Environment
# ============================================================================
# This configuration manages cross-module security group rules:
#   - Fetches security group IDs from other modules via terraform_remote_state
#   - Creates connectivity rules between modules
#   - Enables parallel infrastructure deployment
#
# Dependencies: Must be applied AFTER infrastructure modules (locker, jump-host, etc.)
# ============================================================================

provider "aws" {
  region = var.region
}

# =========================================================================
# DATA SOURCES - FETCH SECURITY GROUP IDs FROM OTHER MODULES
# =========================================================================

# Locker module state
data "terraform_remote_state" "locker" {
  backend = "s3"
  config = {
    bucket = "hyperswitch-dev-terraform-state"
    key    = "dev/eu-central-1/locker/terraform.tfstate"
    region = "eu-central-1"
  }
}

# Jump Host module state (uncomment when ready)
# data "terraform_remote_state" "jump_host" {
#   backend = "s3"
#   config = {
#     bucket = "hyperswitch-dev-terraform-state"
#     key    = "dev/eu-central-1/jump-host/terraform.tfstate"
#     region = "eu-central-1"
#   }
# }

# EKS module state (uncomment when ready)
# data "terraform_remote_state" "eks" {
#   backend = "s3"
#   config = {
#     bucket = "hyperswitch-dev-terraform-state"
#     key    = "dev/eu-central-1/eks/terraform.tfstate"
#     region = "eu-central-1"
#   }
# }

# =========================================================================
# SECURITY RULES MODULE
# =========================================================================

module "security_rules" {
  source = "../../../../modules/composition/security-rules"

  # Security Group IDs from remote state
  locker_sg_id     = data.terraform_remote_state.locker.outputs.security_group_id
  locker_nlb_sg_id = data.terraform_remote_state.locker.outputs.nlb_security_group_id

  # Security Group Rules
  locker_ingress_rules = var.locker_ingress_rules
  locker_egress_rules  = var.locker_egress_rules
  nlb_ingress_rules    = var.nlb_ingress_rules
  nlb_egress_rules     = var.nlb_egress_rules
}
