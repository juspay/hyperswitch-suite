mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "ap-south-2", name = "ap-south-2" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_security_group" {
    defaults = { id = "sg-0123456789abcdef0" }
  }
  mock_data "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/envoy", name = "envoy" }
  }
}
mock_provider "tls" {}

override_module {
  target  = module.asg_security_group
  outputs = { security_group_id = "sg-11111111111111111" }
}

override_module {
  target  = module.asg
  outputs = { autoscaling_group_name = "envoy", autoscaling_group_id = "envoy" }
}

variables {
  environment                        = "sandbox"
  vpc_id                             = "vpc-0123456789abcdef0"
  proxy_subnet_ids                   = ["subnet-0123456789abcdef0"]
  lb_subnet_ids                      = ["subnet-0123456789abcdef0"]
  create_lb                          = false
  existing_lb_arn                    = "arn:aws:elasticloadbalancing:ap-south-2:123456789012:loadbalancer/app/envoy/0123456789abcdef"
  existing_lb_security_group_id      = "sg-22222222222222222"
  existing_tg_arn                    = "arn:aws:elasticloadbalancing:ap-south-2:123456789012:targetgroup/envoy/0123456789abcdef"
  create_target_group                = false
  create_logs_bucket                 = false
  create_iam_role                    = false
  create_instance_profile            = false
  existing_iam_role_name             = "envoy"
  existing_iam_instance_profile_name = "envoy"
  custom_userdata                    = "#!/bin/sh"
  launch_template                    = { create = false, ami_id = "ami-0123456789abcdef0" }
  deployments = {
    stable = { weight = 100, launch_template_id = "lt-0123456789abcdef0", launch_template_version = "1" }
  }
}

run "disabled_by_default" {
  command = plan
  assert {
    condition     = length(aws_cloudfront_vpc_origin.this) == 0 && length(aws_security_group_rule.lb_ingress_cloudfront_vpc_origin) == 0 && output.cloudfront_vpc_origin_id == null
    error_message = "Existing users must not create VPC origins or ingress rules."
  }
}

run "existing_alb_https" {
  command = plan
  variables { cloudfront_vpc_origin = { enabled = true } }
  assert {
    condition     = aws_cloudfront_vpc_origin.this[0].vpc_origin_endpoint_config[0].arn == var.existing_lb_arn && length(aws_security_group_rule.lb_ingress_cloudfront_vpc_origin) == 1
    error_message = "The shared origin must target the external ALB with one HTTPS rule."
  }
  assert {
    condition     = aws_security_group_rule.lb_ingress_cloudfront_vpc_origin["443"].security_group_id == var.existing_lb_security_group_id
    error_message = "Ingress must be added to the ALB group, not AWS's managed group."
  }
}

run "match_viewer_custom_ports" {
  command = plan
  variables {
    alb_http_listener_port  = 8080
    alb_https_listener_port = 8443
    cloudfront_vpc_origin   = { enabled = true, origin_protocol_policy = "match-viewer" }
  }
  assert {
    condition     = toset(keys(aws_security_group_rule.lb_ingress_cloudfront_vpc_origin)) == toset(["8080", "8443"])
    error_message = "match-viewer must allow both configured listener ports."
  }
}

run "external_ingress_ownership" {
  command = plan
  variables {
    existing_lb_security_group_id = null
    cloudfront_vpc_origin         = { enabled = true, manage_security_group_rule = false }
  }
  assert {
    condition     = length(aws_cloudfront_vpc_origin.this) == 1 && length(data.aws_security_group.cloudfront_vpc_origin) == 0 && length(aws_security_group_rule.lb_ingress_cloudfront_vpc_origin) == 0
    error_message = "External ingress ownership must not look up or modify security groups."
  }
}

run "reject_missing_alb" {
  command = plan
  variables {
    existing_lb_arn       = null
    cloudfront_vpc_origin = { enabled = true }
  }
  expect_failures = [aws_cloudfront_vpc_origin.this]
}

run "reject_missing_security_group" {
  command = plan
  variables {
    existing_lb_security_group_id = null
    cloudfront_vpc_origin         = { enabled = true }
  }
  expect_failures = [aws_cloudfront_vpc_origin.this]
}

run "reject_invalid_protocol" {
  command = plan
  variables { cloudfront_vpc_origin = { origin_protocol_policy = "invalid" } }
  expect_failures = [var.cloudfront_vpc_origin]
}

run "managed_alb" {
  command = plan
  override_module {
    target = module.alb
    outputs = {
      arn = "arn:aws:elasticloadbalancing:ap-south-2:123456789012:loadbalancer/app/managed-envoy/1111111111111111"
    }
  }
  override_module {
    target  = module.lb_security_group
    outputs = { security_group_id = "sg-33333333333333333" }
  }
  variables {
    create_lb                     = true
    existing_lb_security_group_id = null
    enable_https_listener         = true
    ssl_certificate_arn           = "arn:aws:acm:ap-south-2:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    cloudfront_vpc_origin         = { enabled = true }
    deployments = {
      stable = {
        weight                    = 100
        launch_template_id        = "lt-0123456789abcdef0"
        launch_template_version   = "1"
        existing_target_group_arn = "arn:aws:elasticloadbalancing:ap-south-2:123456789012:targetgroup/envoy/0123456789abcdef"
      }
    }
  }
  assert {
    condition     = aws_cloudfront_vpc_origin.this[0].vpc_origin_endpoint_config[0].arn == module.alb[0].arn && aws_security_group_rule.lb_ingress_cloudfront_vpc_origin["443"].security_group_id == "sg-33333333333333333"
    error_message = "Managed ALBs must use the module ALB ARN and its selected security group."
  }
}

run "http_only" {
  command = plan
  variables { cloudfront_vpc_origin = { enabled = true, origin_protocol_policy = "http-only" } }
  assert {
    condition     = toset(keys(aws_security_group_rule.lb_ingress_cloudfront_vpc_origin)) == toset(["80"])
    error_message = "HTTP-only origins must not add HTTPS ingress."
  }
}
