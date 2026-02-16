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

  # Logs bucket selection - use created or existing
  logs_bucket_name = var.create_logs_bucket ? module.logs_bucket[0].s3_bucket_id : var.logs_bucket_name
  logs_bucket_arn  = var.create_logs_bucket ? module.logs_bucket[0].s3_bucket_arn : var.logs_bucket_arn
  logs_bucket_id   = var.create_logs_bucket ? module.logs_bucket[0].s3_bucket_id : var.logs_bucket_name

  # Config bucket selection - use created or existing
  config_bucket_name = var.create_config_bucket ? module.config_bucket[0].s3_bucket_id : var.config_bucket_name
  config_bucket_arn  = var.create_config_bucket ? module.config_bucket[0].s3_bucket_arn : var.config_bucket_arn

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
  # Priority: 1) Created role+profile, 2) Created profile for existing role, 3) Existing profile
  instance_profile_name = (
    var.create_iam_role ? module.envoy_iam_role[0].iam_instance_profile_name :
    var.create_instance_profile ? aws_iam_instance_profile.envoy_profile[0].name :
    var.existing_iam_instance_profile_name
  )
  iam_role_arn  = var.create_iam_role ? module.envoy_iam_role[0].iam_role_arn : data.aws_iam_role.existing_envoy_role[0].arn
  iam_role_name = var.create_iam_role ? module.envoy_iam_role[0].iam_role_name : data.aws_iam_role.existing_envoy_role[0].name

  # Launch Template selection - use created or existing
  launch_template_id      = var.use_existing_launch_template ? var.existing_launch_template_id : aws_launch_template.envoy[0].id
  launch_template_version = var.use_existing_launch_template ? var.existing_launch_template_version : aws_launch_template.envoy[0].latest_version

  rollout_version = length(try(data.aws_autoscaling_groups.groups_blue.names, [])) > 0 ? (
    tonumber(
      try(
        [for t in data.aws_autoscaling_group.asg_blue[0].tag : t.value if t.key == "Version"][0],
        "0"
      )
    )
  ) : 0

  standard_version = length(try(data.aws_autoscaling_groups.groups_green.names, [])) > 0 ? (
    tonumber(
      try(
        [for t in data.aws_autoscaling_group.asg_green[0].tag : t.value if t.key == "Version"][0],
        "0"
      )
    )
  ) : local.rollout_version

  target_group_arns = var.create_target_group ? [aws_lb_target_group.envoy[local.standard_version].arn] : [var.existing_tg_arn]

  deployments = var.blue_green_rollout != null ? {
    (local.rollout_version) = {
      lt_version        = data.aws_autoscaling_group.asg_blue[0].launch_template[0].version
      lt_id             = data.aws_autoscaling_group.asg_blue[0].launch_template[0].id
      deployment        = "blue"
      target_group_arns = data.aws_autoscaling_group.asg_blue[0].target_group_arns
      weight            = var.blue_green_rollout.blue_weight
    },
    (local.rollout_version + 1) = {
      lt_version        = local.launch_template_version
      lt_id             = local.launch_template_id
      deployment        = "green"
      target_group_arns = local.target_group_arns
      weight            = var.blue_green_rollout.green_weight
    }
    } : {
    (local.standard_version) = {
      lt_version        = local.launch_template_version
      lt_id             = local.launch_template_id
      deployment        = "blue"
      target_group_arns = local.target_group_arns
      weight            = 100
    }
  }

  target_groups = var.blue_green_rollout != null ? {
    (local.rollout_version)     = "blue",
    (local.rollout_version + 1) = "green"
    } : {
    (local.standard_version) = "blue"
  }
}
