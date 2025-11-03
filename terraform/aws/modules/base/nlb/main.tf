resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "network"
  subnets            = var.subnets
  security_groups    = var.security_groups

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  # Access logs configuration
  dynamic "access_logs" {
    for_each = var.access_logs.enabled ? [1] : []
    content {
      enabled = var.access_logs.enabled
      bucket  = var.access_logs.bucket
      prefix  = var.access_logs.prefix
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
