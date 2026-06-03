<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_route53_record.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs"></a> [access\_logs](#input\_access\_logs) | Access logs configuration | <pre>object({<br/>    enabled = optional(bool, false)<br/>    bucket  = optional(string, null)<br/>    prefix  = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_additional_certificates"></a> [additional\_certificates](#input\_additional\_certificates) | Map of additional certificates to attach to listeners | <pre>map(object({<br/>    listener_key    = string<br/>    certificate_arn = string<br/>  }))</pre> | `{}` | no |
| <a name="input_create_alb"></a> [create\_alb](#input\_create\_alb) | Whether to create the Application Load Balancer. When false, Route53 records and listeners are also skipped. | `bool` | `true` | no |
| <a name="input_drop_invalid_header_fields"></a> [drop\_invalid\_header\_fields](#input\_drop\_invalid\_header\_fields) | Drop invalid header fields | `bool` | `false` | no |
| <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules) | Map of egress rules for the load balancer security group | <pre>map(object({<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    cidr_blocks = list(string)<br/>    description = string<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable\_cross\_zone\_load\_balancing](#input\_enable\_cross\_zone\_load\_balancing) | Enable cross-zone load balancing | `bool` | `true` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | Enable deletion protection on the load balancer | `bool` | `false` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | Enable HTTP/2 | `bool` | `true` | no |
| <a name="input_enable_waf_fail_open"></a> [enable\_waf\_fail\_open](#input\_enable\_waf\_fail\_open) | Enable WAF fail open mode | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/integ/prod) | `string` | n/a | yes |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | Time in seconds that the connection is allowed to be idle | `number` | `60` | no |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | Map of ingress rules for the load balancer security group | <pre>map(object({<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    cidr_blocks = list(string)<br/>    description = string<br/>  }))</pre> | <pre>{<br/>  "http": {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "description": "Allow HTTP traffic",<br/>    "from_port": 80,<br/>    "protocol": "tcp",<br/>    "to_port": 80<br/>  },<br/>  "https": {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "description": "Allow HTTPS traffic",<br/>    "from_port": 443,<br/>    "protocol": "tcp",<br/>    "to_port": 443<br/>  }<br/>}</pre> | no |
| <a name="input_internal"></a> [internal](#input\_internal) | Whether the load balancer is internal or external | `bool` | `false` | no |
| <a name="input_listeners"></a> [listeners](#input\_listeners) | Map of listener configurations | <pre>map(object({<br/>    port                = number<br/>    protocol            = string<br/>    ssl_policy          = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")<br/>    certificate_arn     = optional(string, null)<br/>    alpn_policy         = optional(string, null)<br/>    default_action_type = optional(string, "forward")<br/>    target_group_arn    = optional(string, null)<br/>    redirect_config = optional(object({<br/>      protocol    = optional(string, "#{protocol}")<br/>      port        = optional(string, "#{port}")<br/>      host        = optional(string, "#{host}")<br/>      path        = optional(string, "/#{path}")<br/>      query       = optional(string, "#{query}")<br/>      status_code = optional(string, "HTTP_301")<br/>    }), null)<br/>    fixed_response_config = optional(object({<br/>      content_type = optional(string, "text/plain")<br/>      message_body = optional(string, null)<br/>      status_code  = optional(string, "200")<br/>    }), null)<br/>  }))</pre> | <pre>{<br/>  "http": {<br/>    "default_action_type": "fixed-response",<br/>    "fixed_response_config": {<br/>      "content_type": "text/plain",<br/>      "message_body": "OK",<br/>      "status_code": "200"<br/>    },<br/>    "port": 80,<br/>    "protocol": "HTTP"<br/>  }<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the load balancer | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_route53_records"></a> [route53\_records](#input\_route53\_records) | Map of Route53 DNS records to create for the load balancer. When create\_as\_alias is true, creates an alias record pointing to the ALB. When false, creates a standard record with ttl that defaults to ALB DNS. | <pre>map(object({<br/>    name                         = string<br/>    type                         = optional(string, "A")<br/>    create_as_alias              = optional(bool, false)<br/>    ttl                          = optional(number, null)<br/>    alias_evaluate_target_health = optional(bool, true)<br/>    allow_overwrite              = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_route53_zone"></a> [route53\_zone](#input\_route53\_zone) | Route53 hosted zone configuration. Either provide an existing zone\_id or create a new zone | <pre>object({<br/>    create            = optional(bool, false)<br/>    zone_id           = optional(string, null)<br/>    name              = optional(string, null)<br/>    comment           = optional(string, "Managed by Terraform")<br/>    force_destroy     = optional(bool, false)<br/>    delegation_set_id = optional(string, null)<br/>    # VPC configuration for private hosted zones<br/>    vpc = optional(object({<br/>      vpc_id     = optional(string, null)<br/>      vpc_region = optional(string, null)<br/>    }), null)<br/>    tags = optional(map(string), {})<br/>  })</pre> | <pre>{<br/>  "create": false<br/>}</pre> | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnet IDs to attach to the load balancer | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the load balancer will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | ARN of the Application Load Balancer |
| <a name="output_alb_arn_suffix"></a> [alb\_arn\_suffix](#output\_alb\_arn\_suffix) | ARN suffix of the Application Load Balancer (useful for CloudWatch metrics) |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | DNS name of the Application Load Balancer |
| <a name="output_alb_id"></a> [alb\_id](#output\_alb\_id) | ID of the Application Load Balancer |
| <a name="output_alb_name"></a> [alb\_name](#output\_alb\_name) | Name of the Application Load Balancer |
| <a name="output_alb_tags_all"></a> [alb\_tags\_all](#output\_alb\_tags\_all) | Map of tags assigned to the Load Balancer |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | Zone ID of the Application Load Balancer |
| <a name="output_listener_arns"></a> [listener\_arns](#output\_listener\_arns) | Map of listener keys to listener ARNs |
| <a name="output_listener_details"></a> [listener\_details](#output\_listener\_details) | Map of listener keys with port and protocol details |
| <a name="output_listener_ids"></a> [listener\_ids](#output\_listener\_ids) | Map of listener keys to listener IDs |
| <a name="output_route53_name_servers"></a> [route53\_name\_servers](#output\_route53\_name\_servers) | Name servers of the created Route53 hosted zone (for delegation) |
| <a name="output_route53_record_fqdns"></a> [route53\_record\_fqdns](#output\_route53\_record\_fqdns) | FQDNs of the created Route53 records |
| <a name="output_route53_record_names"></a> [route53\_record\_names](#output\_route53\_record\_names) | Names of the created Route53 records |
| <a name="output_route53_zone_arn"></a> [route53\_zone\_arn](#output\_route53\_zone\_arn) | ARN of the Route53 hosted zone (if created) |
| <a name="output_route53_zone_id"></a> [route53\_zone\_id](#output\_route53\_zone\_id) | ID of the Route53 hosted zone (if created) |
| <a name="output_route53_zone_name"></a> [route53\_zone\_name](#output\_route53\_zone\_name) | Name of the Route53 hosted zone (if created) |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the load balancer security group |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the load balancer security group |
<!-- END_TF_DOCS -->