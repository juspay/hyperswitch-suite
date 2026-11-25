locals {
  cloudfront_vpc_origin_lb_arn = var.create_lb ? module.alb[0].arn : var.existing_lb_arn
  cloudfront_vpc_origin_ports = var.cloudfront_vpc_origin.origin_protocol_policy == "https-only" ? toset([tostring(var.alb_https_listener_port)]) : (
    var.cloudfront_vpc_origin.origin_protocol_policy == "http-only" ? toset([tostring(var.alb_http_listener_port)]) :
    toset([tostring(var.alb_http_listener_port), tostring(var.alb_https_listener_port)])
  )
}

# CloudFront is global; the ALB ARN selects the regional VPC connection.
resource "aws_cloudfront_vpc_origin" "this" {
  count = var.cloudfront_vpc_origin.enabled ? 1 : 0

  vpc_origin_endpoint_config {
    name                   = coalesce(var.cloudfront_vpc_origin.name, "${local.name_prefix}-vpc-origin")
    arn                    = local.cloudfront_vpc_origin_lb_arn
    http_port              = var.alb_http_listener_port
    https_port             = var.alb_https_listener_port
    origin_protocol_policy = var.cloudfront_vpc_origin.origin_protocol_policy
    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
  tags = local.common_tags
  timeouts {
    create = var.cloudfront_vpc_origin.timeouts.create
    update = var.cloudfront_vpc_origin.timeouts.update
    delete = var.cloudfront_vpc_origin.timeouts.delete
  }
  lifecycle {
    precondition {
      condition     = var.create_lb || can(regex(":loadbalancer/app/", var.existing_lb_arn))
      error_message = "CloudFront VPC origins require a managed ALB or an existing Application Load Balancer ARN."
    }
    precondition {
      condition     = !var.cloudfront_vpc_origin.manage_security_group_rule || local.lb_security_group_id != null
      error_message = "Supply existing_lb_security_group_id when managing VPC origin ingress for an external ALB."
    }
    precondition {
      condition = !var.create_lb || (
        (var.cloudfront_vpc_origin.origin_protocol_policy == "http-only" || var.enable_https_listener) &&
        (var.cloudfront_vpc_origin.origin_protocol_policy == "https-only" || var.enable_http_listener)
      )
      error_message = "Enable the ALB listeners required by cloudfront_vpc_origin.origin_protocol_policy."
    }
  }
}

# AWS owns this group. Discover it after VPC origin creation; do not modify it.
data "aws_security_group" "cloudfront_vpc_origin" {
  count = var.cloudfront_vpc_origin.enabled && var.cloudfront_vpc_origin.manage_security_group_rule ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "group-name"
    values = ["CloudFront-VPCOrigins-Service-SG"]
  }
  depends_on = [aws_cloudfront_vpc_origin.this]
}

# Additive ingress on the ALB's own group. Remove public rules in their owning
# unit only after all consumers have migrated to private connectivity.
resource "aws_security_group_rule" "lb_ingress_cloudfront_vpc_origin" {
  for_each = var.cloudfront_vpc_origin.enabled && var.cloudfront_vpc_origin.manage_security_group_rule ? local.cloudfront_vpc_origin_ports : toset([])

  type                     = "ingress"
  security_group_id        = local.lb_security_group_id
  source_security_group_id = data.aws_security_group.cloudfront_vpc_origin[0].id
  protocol                 = "tcp"
  from_port                = tonumber(each.value)
  to_port                  = tonumber(each.value)
  description              = "Allow CloudFront VPC origins to the Envoy ALB"
}
