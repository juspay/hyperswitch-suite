resource "aws_lb_listener" "this" {
  load_balancer_arn = var.load_balancer_arn
  port              = var.port
  protocol          = var.protocol
  ssl_policy        = var.protocol == "HTTPS" || var.protocol == "TLS" ? var.ssl_policy : null
  certificate_arn   = var.protocol == "HTTPS" || var.protocol == "TLS" ? var.certificate_arn : null
  alpn_policy       = var.alpn_policy

  # Default action - forward to target group
  dynamic "default_action" {
    for_each = var.default_action_type == "forward" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = var.target_group_arn
    }
  }

  # Default action - redirect
  dynamic "default_action" {
    for_each = var.default_action_type == "redirect" ? [1] : []
    content {
      type = "redirect"
      redirect {
        protocol    = var.redirect_config.protocol
        port        = var.redirect_config.port
        host        = var.redirect_config.host
        path        = var.redirect_config.path
        query       = var.redirect_config.query
        status_code = var.redirect_config.status_code
      }
    }
  }

  # Default action - fixed response
  dynamic "default_action" {
    for_each = var.default_action_type == "fixed-response" ? [1] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = var.fixed_response_config.content_type
        message_body = var.fixed_response_config.message_body
        status_code  = var.fixed_response_config.status_code
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-listener"
    }
  )
}
