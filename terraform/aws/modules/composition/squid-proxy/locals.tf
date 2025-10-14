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

  # User data template
  userdata_content = templatefile("${path.module}/templates/userdata.sh.tpl", {
    config_bucket = var.config_bucket_name
    logs_bucket   = module.logs_bucket.bucket_id
    squid_port    = var.squid_port
    environment   = var.environment
    region        = data.aws_region.current.name
  })
}
