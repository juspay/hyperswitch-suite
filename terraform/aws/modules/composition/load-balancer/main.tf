# =========================================================================
# ACM CERTIFICATE (Optional)
# =========================================================================
module "acm" {
  count = local.create_acm_certificate ? 1 : 0

  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.0"

  domain_name = var.acm.domain_name

  subject_alternative_names = var.acm.subject_alternative_names

  zone_id = var.acm.zone_id

  validation_method = var.acm.validation_method

  create_route53_records  = var.acm.create_route53_records
  validate_certificate    = var.acm.validate_certificate
  validation_record_fqdns = var.acm.validation_record_fqdns
  zones                   = var.acm.zones

  create_route53_records_only               = var.acm.create_route53_records_only
  distinct_domain_names                     = var.acm.distinct_domain_names
  acm_certificate_domain_validation_options = var.acm.acm_certificate_domain_validation_options

  wait_for_validation                = var.acm.wait_for_validation
  validation_timeout                 = var.acm.validation_timeout
  validation_allow_overwrite_records = var.acm.validation_allow_overwrite_records

  certificate_transparency_logging_preference = var.acm.certificate_transparency_logging_preference

  tags = merge(
    local.common_tags,
    var.acm.tags,
    {
      Name = "${local.name_prefix}-cert"
    }
  )
}

# =========================================================================
# SECURITY GROUP
# =========================================================================
resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for ${var.project_name} load balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-sg"
    }
  )
}

# =========================================================================
# SECURITY GROUP RULES - INGRESS
# =========================================================================
resource "aws_security_group_rule" "ingress" {
  for_each = var.ingress_rules

  security_group_id = aws_security_group.this.id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

# =========================================================================
# SECURITY GROUP RULES - EGRESS
# =========================================================================
resource "aws_security_group_rule" "egress" {
  for_each = var.egress_rules

  security_group_id = aws_security_group.this.id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

# =========================================================================
# APPLICATION LOAD BALANCER
# =========================================================================
resource "aws_lb" "this" {
  name               = local.lb_name
  internal           = var.internal
  load_balancer_type = "application"
  subnets            = var.subnets
  security_groups    = [aws_security_group.this.id]

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.enable_http2
  enable_waf_fail_open             = var.enable_waf_fail_open
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  idle_timeout                     = var.idle_timeout

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
    local.common_tags,
    {
      Name = local.lb_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =========================================================================
# LISTENERS
# =========================================================================
resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.protocol == "HTTPS" ? each.value.ssl_policy : null
  certificate_arn   = each.value.protocol == "HTTPS" ? (each.value.certificate_arn != null ? each.value.certificate_arn : local.certificate_arn) : null
  alpn_policy       = each.value.alpn_policy

  dynamic "default_action" {
    for_each = each.value.default_action_type == "forward" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = each.value.target_group_arn
    }
  }

  dynamic "default_action" {
    for_each = each.value.default_action_type == "redirect" ? [each.value.redirect_config] : []
    content {
      type = "redirect"
      redirect {
        protocol    = default_action.value.protocol
        port        = default_action.value.port
        host        = default_action.value.host
        path        = default_action.value.path
        query       = default_action.value.query
        status_code = default_action.value.status_code
      }
    }
  }

  dynamic "default_action" {
    for_each = each.value.default_action_type == "fixed-response" ? [each.value.fixed_response_config] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = default_action.value.content_type
        message_body = default_action.value.message_body
        status_code  = default_action.value.status_code
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-listener-${each.key}"
    }
  )
}

# =========================================================================
# LISTENER CERTIFICATES (Additional Certificates)
# =========================================================================
resource "aws_lb_listener_certificate" "this" {
  for_each = var.additional_certificates

  listener_arn    = aws_lb_listener.this[each.value.listener_key].arn
  certificate_arn = each.value.certificate_arn
}

# =========================================================================
# ROUTE53 HOSTED ZONE
# =========================================================================
resource "aws_route53_zone" "this" {
  count = var.route53_zone.create ? 1 : 0

  name              = var.route53_zone.name
  comment           = var.route53_zone.comment
  force_destroy     = var.route53_zone.force_destroy
  delegation_set_id = var.route53_zone.delegation_set_id

  # VPC association for private hosted zones
  dynamic "vpc" {
    for_each = var.route53_zone.vpc != null && var.route53_zone.vpc.vpc_id != null ? [var.route53_zone.vpc] : []
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  tags = merge(
    local.common_tags,
    var.route53_zone.tags,
    {
      Name = var.route53_zone.name
    }
  )
}

# =========================================================================
# ROUTE53 RECORDS
# =========================================================================
resource "aws_route53_record" "alb" {
  for_each = var.route53_records

  zone_id         = var.route53_zone.create ? aws_route53_zone.this[0].zone_id : var.route53_zone.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = each.value.create_as_alias ? null : each.value.ttl
  records         = each.value.create_as_alias ? null : [aws_lb.this.dns_name]
  allow_overwrite = each.value.allow_overwrite

  # Alias block for alias records pointing to ALB
  dynamic "alias" {
    for_each = each.value.create_as_alias ? [1] : []
    content {
      name                   = aws_lb.this.dns_name
      zone_id                = aws_lb.this.zone_id
      evaluate_target_health = each.value.alias_evaluate_target_health
    }
  }
}
