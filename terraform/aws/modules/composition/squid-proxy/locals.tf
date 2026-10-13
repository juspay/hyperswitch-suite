locals {
  # Naming convention
  name_prefix = "${var.environment}-${var.project_name}-${var.name_override}"

  # Common tags merged with environment-specific tags
  common_tags = merge(
    var.tags,
    {
      Module = try(var.tags.Module, "composition/squid-proxy")
    }
  )

  # Instance tags (propagated to EC2 instances)
  instance_tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-instance"
    }
  )

  # Logs bucket selection - use created or existing
  logs_bucket_name = var.create_logs_bucket ? module.logs_bucket[0].s3_bucket_id : var.logs_bucket_name
  logs_bucket_arn  = var.create_logs_bucket ? module.logs_bucket[0].s3_bucket_arn : var.logs_bucket_arn
  logs_bucket_id   = var.create_logs_bucket ? module.logs_bucket[0].s3_bucket_id : var.logs_bucket_name

  # Config bucket selection - use created or existing
  config_bucket_name = var.create_config_bucket ? module.config_bucket[0].s3_bucket_id : var.config_bucket_name
  config_bucket_arn  = var.create_config_bucket ? module.config_bucket[0].s3_bucket_arn : var.config_bucket_arn

  # Userdata templating - replace placeholders with actual values
  userdata_content = replace(
    replace(
      replace(
        replace(
          var.custom_userdata,
          "{{config_bucket}}", local.config_bucket_name
        ),
        "{{logs_bucket}}", local.logs_bucket_id
      ),
      "{{bucket-path-prefix}}", var.s3_config_path_prefix
    ),
    "{{bucket-name}}", local.config_bucket_name
  )

  # config_files templating - same placeholder substitution as userdata_content,
  # applied to every uploaded config file's content (e.g. vector.toml's
  # {{loki_endpoint}} Loki sink URL, so it can be region-coded by the caller
  # instead of hardcoded per-region in a static file). Callers can supply further
  # {{key}} placeholders through config_files_vars; unknown placeholders are left as-is.
  config_files_vars = merge({ loki_endpoint = var.loki_endpoint }, var.config_files_vars)

  # Split on "{{" and resolve each segment's leading "key}}" against config_files_vars,
  # since HCL has no fold to chain replace() over a map.
  config_files_content = {
    for key, path in var.config_files : key => join("", [
      for i, part in split("{{", file(path)) :
      i == 0 ? part : (
        can(local.config_files_vars[regex("^([A-Za-z0-9_-]+)}}", part)[0]])
        ? "${local.config_files_vars[regex("^([A-Za-z0-9_-]+)}}", part)[0]]}${substr(part, length(regex("^([A-Za-z0-9_-]+)}}", part)[0]) + 2, -1)}"
        : "{{${part}"
      )
    ])
  }

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
