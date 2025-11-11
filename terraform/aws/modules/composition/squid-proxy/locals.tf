locals {
  # Naming convention
  name_prefix = "${var.environment}-${var.project_name}-squid"

  # Common tags merged with environment-specific tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Service     = "squid-proxy"
      ManagedBy   = "Terraform"
      Module      = "composition/squid-proxy"
    }
  )

  # Instance tags (propagated to EC2 instances)
  instance_tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-instance"
    }
  )

  # Logs bucket selection - use created or existing
  logs_bucket_name = var.create_logs_bucket ? module.logs_bucket[0].bucket_name : var.logs_bucket_name
  logs_bucket_arn  = var.create_logs_bucket ? module.logs_bucket[0].bucket_arn : var.logs_bucket_arn
  logs_bucket_id   = var.create_logs_bucket ? module.logs_bucket[0].bucket_id : var.logs_bucket_name

  # Config bucket selection - use created or existing
  config_bucket_name = var.create_config_bucket ? module.config_bucket[0].bucket_name : var.config_bucket_name
  config_bucket_arn  = var.create_config_bucket ? module.config_bucket[0].bucket_arn : var.config_bucket_arn

  # Userdata templating - replace placeholders with actual values
  userdata_content = replace(
    replace(
      replace(
        var.custom_userdata,
        "{{config_bucket}}", local.config_bucket_name
      ),
      "{{logs_bucket}}", local.logs_bucket_id
    ),
    "{{bucket-name}}", local.config_bucket_name
  )

  # IAM role selection - use created or existing
  # Priority: 1) Created role+profile, 2) Created profile for existing role, 3) Existing profile
  instance_profile_name = (
    var.create_iam_role ? module.squid_iam_role[0].instance_profile_name :
    var.create_instance_profile ? aws_iam_instance_profile.squid_profile[0].name :
    var.existing_iam_instance_profile_name
  )
  iam_role_arn  = var.create_iam_role ? module.squid_iam_role[0].role_arn : data.aws_iam_role.existing_squid_role[0].arn
  iam_role_name = var.create_iam_role ? module.squid_iam_role[0].role_name : data.aws_iam_role.existing_squid_role[0].name

  # Launch Template selection - use created or existing
  # IMPORTANT: Use explicit version number instead of "$Latest" to ensure
  # Terraform detects changes and triggers instance refresh automatically
  launch_template_id      = var.use_existing_launch_template ? var.existing_launch_template_id : module.launch_template[0].lt_id
  launch_template_version = var.use_existing_launch_template ? var.existing_launch_template_version : tostring(module.launch_template[0].lt_latest_version)
}
