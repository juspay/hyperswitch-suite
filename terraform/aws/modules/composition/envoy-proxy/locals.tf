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

  # User data template
  userdata_content = templatefile("${path.module}/templates/userdata.sh.tpl", {
    config_bucket     = var.config_bucket_name
    logs_bucket       = module.logs_bucket.bucket_id
    envoy_admin_port  = var.envoy_admin_port
    envoy_listener_port = var.envoy_listener_port
    environment       = var.environment
    region            = data.aws_region.current.name
  })
}
