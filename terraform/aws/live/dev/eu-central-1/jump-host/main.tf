# ============================================================================
# Jump Host Deployment - Dev Environment
# ============================================================================
# This configuration can deploy in two modes:
#   - Dual Mode (enable_external_jump = true, default):
#       - External Jump: Public subnet with public IP (accessible via Session Manager)
#       - Internal Jump: Private subnet (accessible from external jump via SSH)
#   - Standalone Mode (enable_external_jump = false):
#       - Internal Jump only: Private subnet with SSM access forced on
#
# Access Method: AWS Systems Manager Session Manager (IAM-based auth)
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
  region = var.region

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

  # Jump Host Mode Configuration
  enable_external_jump = var.enable_external_jump

  # SSM Session Manager Configuration
  enable_internal_jump_ssm     = var.enable_internal_jump_ssm
  enable_ssm_session_encryption = var.enable_ssm_session_encryption

  # SSM Session Preferences
  ssm_idle_session_timeout       = var.ssm_idle_session_timeout
  ssm_max_session_duration       = var.ssm_max_session_duration
  ssm_run_as_user                = var.ssm_run_as_user
  ssm_cloudwatch_logging_enabled = var.ssm_cloudwatch_logging_enabled
  ssm_cloudwatch_log_group_name  = var.ssm_cloudwatch_log_group_name
  ssm_s3_logging_enabled         = var.ssm_s3_logging_enabled
  ssm_s3_bucket_name             = var.ssm_s3_bucket_name
  ssm_s3_key_prefix              = var.ssm_s3_key_prefix

  # SSM Session Preferences - Toggle and Custom Profiles
  create_ssm_session_preferences = var.create_ssm_session_preferences
  ssm_shell_profile_linux        = var.ssm_shell_profile_linux
  ssm_shell_profile_windows      = var.ssm_shell_profile_windows

  # Migration Mode Configuration
  enable_migration_mode = var.enable_migration_mode

  # Tags
  tags = var.common_tags
}
