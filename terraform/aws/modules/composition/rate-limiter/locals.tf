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

  # Use provided AMI ID or default to Amazon Linux 2023
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023[0].id

  # Determine instance profile name
  instance_profile_name = var.create_iam_role ? module.iam_role[0].iam_instance_profile_name : var.iam_instance_profile_name

  # Determine launch template ID and version
  launch_template_id      = var.use_existing_launch_template ? var.existing_launch_template_id : aws_launch_template.this[0].id
  launch_template_version = var.use_existing_launch_template ? var.existing_launch_template_version : aws_launch_template.this[0].default_version

  # User data content
  userdata_content = var.user_data
}
