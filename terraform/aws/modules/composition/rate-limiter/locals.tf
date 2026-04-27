locals {
  name_prefix = "${var.environment}-${var.project_name}-rate-limiter"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "rate-limiter"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  instance_tags = merge(
    local.common_tags,
    {
      Name = local.name_prefix
    }
  )

  # Config bucket selection - use created or existing
  config_bucket_name = var.create_config_bucket ? module.config_bucket[0].s3_bucket_id : var.config_bucket_name
  config_bucket_arn  = var.create_config_bucket ? module.config_bucket[0].s3_bucket_arn : var.config_bucket_arn

  # Rate limiter config file paths in S3 - constructed internally from bucket and filenames
  ratelimit_env_config_file_path = "s3://${local.config_bucket_name}/${var.ratelimit_env_config_filename}"
  ratelimit_descriptor_file_path = "s3://${local.config_bucket_name}/${var.ratelimit_descriptor_filename}"

  # Use provided AMI ID or default to Amazon Linux 2023
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023[0].id

  # Determine instance profile name
  instance_profile_name = var.create_iam_role ? module.iam_role[0].iam_instance_profile_name : var.iam_instance_profile_name

  # Determine launch template ID and version
  launch_template_id      = var.use_existing_launch_template ? var.existing_launch_template_id : aws_launch_template.this[0].id
  launch_template_version = var.use_existing_launch_template ? var.existing_launch_template_version : aws_launch_template.this[0].default_version

  # User data content - render template with configurable values
  userdata_content = var.user_data != null ? var.user_data : templatefile("${path.module}/templates/userdata.sh", {
    # Wazuh settings
    update_wazuh       = var.userdata_config.update_wazuh
    wazuh_manager_addr = var.userdata_config.wazuh_manager_addr
    wazuh_worker_addr  = var.userdata_config.wazuh_worker_addr
    wazuh_group        = var.userdata_config.wazuh_group
    wazuh_tag          = var.userdata_config.wazuh_tag

    # Stack and logging settings
    stack_svc       = var.userdata_config.stack_svc
    syslog_rotation = var.userdata_config.syslog_rotation
    region          = data.aws_region.current.region

    # User and access settings
    sudo_user_list   = var.userdata_config.sudo_user_list
    normal_user_list = var.userdata_config.normal_user_list
    ssh_service      = var.userdata_config.ssh_service

    # Network settings
    additional_inbound_ports  = var.userdata_config.additional_inbound_ports
    additional_outbound_ports = var.userdata_config.additional_outbound_ports

    # Application configuration paths - constructed from S3 bucket
    ratelimit_env_config_file_path = local.ratelimit_env_config_file_path
    ratelimit_descriptor_file_path = local.ratelimit_descriptor_file_path

    # ElastiCache connection info
    elasticache_enabled          = var.elasticache_config.enabled
    elasticache_primary_endpoint = var.elasticache_config.enabled ? module.elasticache[0].replication_group_primary_endpoint_address : ""
    elasticache_reader_endpoint  = var.elasticache_config.enabled ? module.elasticache[0].replication_group_reader_endpoint_address : ""
    elasticache_port             = var.elasticache_config.enabled ? module.elasticache[0].replication_group_port : var.elasticache_config.port
  })

  # Health check port defaults to traffic_port if not specified
  health_check_port = var.health_check_port != null ? var.health_check_port : var.traffic_port
}
