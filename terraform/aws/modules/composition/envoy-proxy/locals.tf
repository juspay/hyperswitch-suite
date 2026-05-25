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

  default_eks_cluster_name = "${var.environment}-${var.project_name}-cluster"
  eks_cluster_name = var.eks_cluster_name != "" ? var.eks_cluster_name : local.default_eks_cluster_name

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
    "{{eks_cluster_name}}", local.eks_cluster_name
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

  auto_scaling_groups = {
    for name, d in var.deployments : name => {
      asg_name                = coalesce(d.asg_name, "${local.name_prefix}-${name}")
      weight                  = d.weight
      desired_capacity        = coalesce(d.desired_capacity, var.desired_capacity)
      launch_template_id      = d.launch_template_id != null ? d.launch_template_id : aws_launch_template.envoy[0].id
      launch_template_version = d.launch_template_version
      tg_available            = var.create_target_group || d.existing_target_group_arn != null
    }
  }

  target_groups = {
    for name, d in var.deployments : name => {
      create_tg         = d.existing_target_group_arn == null
      target_group_name = coalesce(d.target_group_name, "${substr("${name}-${local.name_prefix}", 0, 32)}")
    }
  }

  target_group_arns = {
    for name, d in var.deployments : name => d.existing_target_group_arn != null ? d.existing_target_group_arn : (var.create_target_group ? aws_lb_target_group.envoy[name].arn : null)
  }
}
