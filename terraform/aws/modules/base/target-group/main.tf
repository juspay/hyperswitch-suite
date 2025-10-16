resource "aws_lb_target_group" "this" {
  name                 = var.name
  port                 = var.port
  protocol             = var.protocol
  vpc_id               = var.vpc_id
  target_type          = var.target_type
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = var.health_check.enabled
    healthy_threshold   = var.health_check.healthy_threshold
    unhealthy_threshold = var.health_check.unhealthy_threshold
    timeout             = var.health_check.timeout
    interval            = var.health_check.interval
    port                = var.health_check.port
    protocol            = var.health_check.protocol
    path                = var.health_check.path
    matcher             = var.health_check.matcher
  }

  # Only create stickiness block if enabled
  dynamic "stickiness" {
    for_each = var.stickiness.enabled ? [1] : []
    content {
      type            = var.stickiness.type
      cookie_duration = var.stickiness.cookie_duration
      enabled         = var.stickiness.enabled
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
