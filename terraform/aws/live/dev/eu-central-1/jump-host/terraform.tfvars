# ============================================================================
# Development Environment - EU Central 1 - Jump Host Configuration
# ============================================================================
# This file contains configuration values for the dev environment
# Modify values as needed for your deployment
# ============================================================================

# ============================================================================
# Environment & Project Configuration
# ============================================================================
environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# ============================================================================
# Network Configuration
# ============================================================================
# TODO: Replace with your actual VPC and subnet IDs
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"  # Replace with your VPC ID

# Public subnet for external jump host (must have internet gateway)
# Required when enable_external_jump = true, optional otherwise
public_subnet_id = "subnet-xxxxxxxxxxxxxxxxx"  # Replace with your public(management) subnet ID

# Private subnet for internal jump host
private_subnet_id = "subnet-xxxxxxxxxxxxxxxxx"  # Replace with your private(Utils) subnet ID

# ============================================================================
# Jump Host Mode Configuration
# ============================================================================
# Dual Mode (enable_external_jump = true, default):
#   - External Jump: Public subnet with public IP (accessible via Session Manager)
#   - Internal Jump: Private subnet (accessible from external jump via SSH)
# Standalone Mode (enable_external_jump = false):
#   - Internal Jump only: Private subnet with SSM access forced ON

enable_external_jump = true
# ============================================================================
# Instance Configuration
# ============================================================================

# Leave ami_ids as null to automatically use latest Amazon Linux 2023 
# External Jump Host AMI (public subnet) - only used when enable_external_jump = true
external_jump_ami_id = "ami-xxxxxxxxxxxxxxxxx"

# Internal Jump Host AMI (private subnet)
internal_jump_ami_id = "ami-xxxxxxxxxxxxxxxxx"

# Instance type - t3.micro is sufficient for jump hosts (2 vCPU, 1 GB RAM)
# Upgrade to t3.small if needed (2 vCPU, 2 GB RAM)
instance_type = "t3.medium"

# Root volume configuration
root_volume_size = 20    # GB
root_volume_type = "gp3" # General Purpose SSD

# ============================================================================
# Logging Configuration
# ============================================================================
# CloudWatch log retention in days (1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653)
log_retention_days = 30

# ============================================================================
# SSM Session Manager Configuration
# ============================================================================
# Enable SSM Session Manager access for internal jump host
# - When enable_external_jump = true: This allows direct SSM access to internal jump
#   (optional - can still SSH from external jump)
# - When enable_external_jump = false: This is ignored (SSM is forced ON for access)
#
enable_internal_jump_ssm = false

# Enable KMS encryption for SSM sessions
# When true, sessions are encrypted using AWS KMS
enable_ssm_session_encryption = true

# ============================================================================
# SSM Session Manager Preferences
# ============================================================================
# These settings configure the Session Manager preferences for this environment.
# NOTE: This creates an SSM document named 'SSM-SessionManagerRunShell' which
# is the default document for ALL sessions in this AWS account/region.
# If multiple environments share the same AWS account, coordinate carefully.

# Idle session timeout (minutes) - Session terminates after inactivity
ssm_idle_session_timeout = 10

# Maximum session duration (minutes) - Leave empty for unlimited
ssm_max_session_duration = ""

# Run As user - Enables IAM user → OS user mapping
# When set (e.g., "ubuntu"), SSM creates OS users based on IAM user name
# and runs sessions as that user. Example: IAM user "harshvardhan.b" → OS user "harshvardhan.b"
# Leave empty to use default ssm-user
ssm_run_as_user = "ubuntu"

# ---------------------------------------------------------------------------
# CloudWatch logging for SSM sessions
# ---------------------------------------------------------------------------
# Option 1: Use existing CloudWatch log group (default)
#   - Set create_ssm_cloudwatch_log_group = false
#   - Set ssm_cloudwatch_log_group_name to your existing log group name
# Option 2: Create new CloudWatch log group
#   - Set create_ssm_cloudwatch_log_group = true
#   - Set ssm_cloudwatch_log_group_name_prefix (optional, defaults to '/aws/ssm/session-logs')
#   - Set ssm_cloudwatch_log_group_retention_days (optional, defaults to 90)
# ---------------------------------------------------------------------------
ssm_cloudwatch_logging_enabled        = true
create_ssm_cloudwatch_log_group       = false  # Set to true for initial setup
ssm_cloudwatch_log_group_name         = ""     # Required when create_ssm_cloudwatch_log_group = false
ssm_cloudwatch_log_group_name_prefix  = "/aws/ssm/session-logs"
ssm_cloudwatch_log_group_retention_days = 90

# ---------------------------------------------------------------------------
# S3 logging for SSM sessions
# ---------------------------------------------------------------------------
# Option 1: Use existing S3 bucket (default)
#   - Set create_ssm_s3_bucket = false
#   - Set ssm_s3_bucket_name to your existing bucket name
# Option 2: Create new S3 bucket
#   - Set create_ssm_s3_bucket = true
#   - Set ssm_s3_bucket_name_prefix (optional, defaults to 'ssm-session-logs')
#   - Set ssm_s3_bucket_versioning (optional, defaults to true)
#   - Set ssm_s3_bucket_lifecycle_days (optional, defaults to 90, set to 0 to disable)
# ---------------------------------------------------------------------------
ssm_s3_logging_enabled     = false
create_ssm_s3_bucket       = false  # Set to true for initial setup
ssm_s3_bucket_name         = ""     # Required when create_ssm_s3_bucket = false
ssm_s3_key_prefix          = "session-manager"
ssm_s3_bucket_name_prefix  = "ssm-session-logs"
ssm_s3_bucket_versioning   = true
ssm_s3_bucket_lifecycle_days = 90

# ---------------------------------------------------------------------------
# Toggle SSM Session Preferences Creation
# ---------------------------------------------------------------------------
# Set to false if another environment in the same AWS account already
# manages the SSM-SessionManagerRunShell document (account-level setting).
create_ssm_session_preferences = true

# ---------------------------------------------------------------------------
# Shell Profiles - Commands that run when session starts
# ---------------------------------------------------------------------------
# Configure the welcome message and session setup commands.
# Example:
# ssm_shell_profile_linux = <<-EOT
#   exec /bin/bash
#   timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')
#   user=$(whoami)
#   cd /home/$user
#   echo $timestamp && echo "Welcome $user!"
#   echo "You have logged in to a Juspay Hyperswitch Sandbox instance. Note that all session activity is being logged."
# EOT
#
ssm_shell_profile_linux   = ""
ssm_shell_profile_windows = ""

# ============================================================================
# Migration Mode Configuration
# ============================================================================
# Enable SSM SendCommand permissions for Packer AMI migration (SECURITY RISK)
# This grants sudo-level access via SSM commands and should ONLY be enabled
# during active Packer migrations. Set to false after migration is complete.
#
# Permissions affected:
#   - ssm:DescribeInstanceInformation
#   - ssm:SendCommand
#   - ssm:GetCommandInvocation
#   - ssm:ListCommandInvocations
#
# Default: false (secure)
# Set to true only when running Packer migration, then immediately revert to false
enable_migration_mode = false

# ============================================================================
# Tags
# ============================================================================

common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}



