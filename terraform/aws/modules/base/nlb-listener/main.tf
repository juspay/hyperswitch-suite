resource "aws_lb_listener" "this" {
  count = var.create ? 1 : 0

  load_balancer_arn = var.load_balancer_arn
  port              = var.port
  protocol          = var.protocol

  # SSL/TLS configuration (only for TLS protocol)
  ssl_policy      = var.protocol == "TLS" ? var.ssl_policy : null
  certificate_arn = var.protocol == "TLS" ? var.certificate_arn : null
  alpn_policy     = var.alpn_policy

  # Default action - forward to target group
  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-listener"
    }
  )
}
