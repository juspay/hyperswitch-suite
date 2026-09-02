include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  extra_atlantis_dependencies = [
    "templates/userdata.sh"
  ]
}

dependency "vpc_network" {
  config_path = "../vpc-network"

  mock_outputs = {
    utils_subnet_ids = ["mock-utils_subnet_ids"]
    vpc_id           = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/jump-host?ref=jump-host-v0.2.1"
}

inputs = {
  # Environment Configuration
  environment  = include.root.locals.environment.short
  region       = include.root.locals.region
  project_name = include.root.locals.project_name

  # Network Configuration
  vpc_id    = dependency.vpc_network.outputs.vpc_id
  subnet_id = dependency.vpc_network.outputs.utils_subnet_ids[0]

  # AMI Configuration
  ami_id = values.ami_id

  # Instance Configuration
  instance_type    = "t3.medium"
  root_volume_size = 30
  root_volume_type = "gp3"

  # Logging Configuration
  log_retention_days = 30

  # SSM Session Encryption
  enable_ssm_session_encryption = false

  # SSM Session Preferences
  ssm_idle_session_timeout = 10
  ssm_max_session_duration = ""
  ssm_run_as_user          = "ubuntu"

  # ---------------------------------------------------------------------------
  # CloudWatch logging for SSM sessions - Create new log group
  # ---------------------------------------------------------------------------
  ssm_cloudwatch_logging_enabled          = false
  create_ssm_cloudwatch_log_group         = true
  ssm_cloudwatch_log_group_name           = ""
  ssm_cloudwatch_log_group_name_prefix    = "/aws/ssm/session-logs"
  ssm_cloudwatch_log_group_retention_days = 90

  # ---------------------------------------------------------------------------
  # S3 logging for SSM sessions - Create new S3 bucket
  # ---------------------------------------------------------------------------
  ssm_s3_logging_enabled       = false
  create_ssm_s3_bucket         = true
  ssm_s3_bucket_name           = ""
  ssm_s3_key_prefix            = "session-manager"
  ssm_s3_bucket_name_prefix    = "ssm-session-logs"
  ssm_s3_bucket_versioning     = true
  ssm_s3_bucket_lifecycle_days = 90

  # Create SSM Session Preferences Document
  # Can be disabled per stack when the regional document already exists.
  create_ssm_session_preferences = try(values.create_ssm_session_preferences, true)
  ssm_shell_profile_linux        = <<-EOT
    exec /bin/bash
    timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')
    user=$(whoami)
    cd /home/$user
    echo $timestamp && echo "Welcome $user!"
    echo "You have logged in to a Juspay Hyperswitch instance. Note that all session activity is being logged."
  EOT
  ssm_shell_profile_windows      = ""

  # Migration Mode - disabled for security
  enable_migration_mode = false

  # Userdata - Wazuh agent config is optional; provide the wazuh_* stack values
  # to enroll the host with your Wazuh deployment.
  user_data_base64 = base64encode(templatefile("templates/userdata.sh", {
    update_wazuh       = try(values.wazuh_manager_addr, "") != "" ? "Enable" : "Disable"
    wazuh_manager_addr = try(values.wazuh_manager_addr, "NA")
    wazuh_worker_addr  = try(values.wazuh_worker_addr, "NA")
    wazuh_group        = try(values.wazuh_group, "NA")
    wazuh_tag          = try(values.wazuh_tag, "NA")
    sudo_user_list     = try(values.sudo_user_list, "ubuntu")
    region             = include.root.locals.region
  }))

  # Tags
  tags = {
    Environment = include.root.locals.environment.short
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }
}