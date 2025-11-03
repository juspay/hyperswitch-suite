locals {
  # Naming convention
  name_prefix = "${var.environment}-${var.project_name}-envoy"

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Service     = "envoy-proxy"
      ManagedBy   = "Terraform"
      Module      = "composition/envoy-proxy"
    }
  )

  # Instance tags
  instance_tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-instance"
    }
  )

  # Envoy configuration templating - replace placeholders with actual values
  # Supports: {{hyperswitch_cloudfront_dns}}, {{internal_loadbalancer_dns}}, {{eks_cluster_name}}
  envoy_config_content = replace(
    replace(
      replace(
        var.envoy_config_template,
        "{{hyperswitch_cloudfront_dns}}", var.hyperswitch_cloudfront_dns
      ),
      "{{internal_loadbalancer_dns}}", var.internal_loadbalancer_dns
    ),
    "{{eks_cluster_name}}", "${var.environment}-${var.project_name}-cluster"
  )

  # Config bucket selection - use created or existing
  config_bucket_name = var.create_config_bucket ? module.config_bucket[0].bucket_name : var.config_bucket_name
  config_bucket_arn  = var.create_config_bucket ? module.config_bucket[0].bucket_arn : var.config_bucket_arn

  # Userdata templating - replace placeholders with actual values
  # Supports: {{bucket-name}}, {{config_bucket}}, {{logs_bucket}}
  userdata_content = replace(
    replace(
      var.custom_userdata,
      "{{bucket-name}}", local.config_bucket_name
    ),
    "{{config_bucket}}", local.config_bucket_name
  )

  # IAM role selection - use created or existing
  instance_profile_name = var.create_iam_role ? module.envoy_iam_role[0].instance_profile_name : var.existing_iam_instance_profile_name
  iam_role_arn          = var.create_iam_role ? module.envoy_iam_role[0].role_arn : data.aws_iam_role.existing_envoy_role[0].arn
  iam_role_name         = var.create_iam_role ? module.envoy_iam_role[0].role_name : data.aws_iam_role.existing_envoy_role[0].name

  # Launch Template selection - use created or existing
  launch_template_id      = var.use_existing_launch_template ? var.existing_launch_template_id : module.launch_template[0].lt_id
  launch_template_version = var.use_existing_launch_template ? var.existing_launch_template_version : "$Latest"
}
