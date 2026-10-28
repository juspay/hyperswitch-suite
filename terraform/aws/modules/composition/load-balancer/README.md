<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.70 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.70 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb_access_logs_s3"></a> [alb\_access\_logs\_s3](#module\_alb\_access\_logs\_s3) | terraform-aws-modules/s3-bucket/aws | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_delivery.alb_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_delivery) | resource |
| [aws_cloudwatch_log_delivery_destination.alb_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_delivery_destination) | resource |
| [aws_cloudwatch_log_delivery_source.alb_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_delivery_source) | resource |
| [aws_cloudwatch_log_group.alb_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_resource_policy.alb_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy) | resource |
| [aws_kms_key.alb_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_route53_record.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_caller_identity.alb_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.alb_access_logs_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.alb_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_partition.alb_access_logs_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.alb_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_region.alb_access_logs_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs"></a> [access\_logs](#input\_access\_logs) | Access logs configuration | <pre>object({<br/>    enabled = optional(bool, false)<br/>    bucket  = optional(string, null)<br/>    prefix  = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_additional_certificates"></a> [additional\_certificates](#input\_additional\_certificates) | Map of additional certificates to attach to listeners | <pre>map(object({<br/>    listener_key    = string<br/>    certificate_arn = string<br/>  }))</pre> | `{}` | no |
| <a name="input_alb_access_logs_kms_key_arn"></a> [alb\_access\_logs\_kms\_key\_arn](#input\_alb\_access\_logs\_kms\_key\_arn) | Optional existing KMS key ARN for ALB access logs. A rotating key is created when null. | `string` | `null` | no |
| <a name="input_alb_access_logs_load_balancer_arns"></a> [alb\_access\_logs\_load\_balancer\_arns](#input\_alb\_access\_logs\_load\_balancer\_arns) | Existing ALB ARNs keyed by stable names. Used for Kubernetes-managed load balancers without importing their resources. | `map(string)` | `{}` | no |
| <a name="input_alb_access_logs_log_group_name"></a> [alb\_access\_logs\_log\_group\_name](#input\_alb\_access\_logs\_log\_group\_name) | Optional custom CloudWatch log group name for ALB access logs. | `string` | `null` | no |
| <a name="input_alb_access_logs_retention_days"></a> [alb\_access\_logs\_retention\_days](#input\_alb\_access\_logs\_retention\_days) | CloudWatch retention period for ALB access logs. | `number` | `30` | no |
| <a name="input_alb_access_logs_s3_bucket_name"></a> [alb\_access\_logs\_s3\_bucket\_name](#input\_alb\_access\_logs\_s3\_bucket\_name) | Optional name for the managed ALB access log bucket. | `string` | `null` | no |
| <a name="input_alb_access_logs_s3_prefix"></a> [alb\_access\_logs\_s3\_prefix](#input\_alb\_access\_logs\_s3\_prefix) | S3 key prefix for ALB access logs. Must not contain AWSLogs. | `string` | `"alb"` | no |
| <a name="input_create_alb"></a> [create\_alb](#input\_create\_alb) | Whether to create the Application Load Balancer. When false, Route53 records and listeners are also skipped. | `bool` | `true` | no |
| <a name="input_create_alb_access_logs_s3_bucket"></a> [create\_alb\_access\_logs\_s3\_bucket](#input\_create\_alb\_access\_logs\_s3\_bucket) | Create an SSE-S3 encrypted ALB access log bucket, including for controller-managed ALBs. | `bool` | `false` | no |
| <a name="input_drop_invalid_header_fields"></a> [drop\_invalid\_header\_fields](#input\_drop\_invalid\_header\_fields) | Drop invalid header fields | `bool` | `false` | no |
| <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules) | Map of egress rules for the load balancer security group | <pre>map(object({<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    cidr_blocks = list(string)<br/>    description = string<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_alb_access_logs"></a> [enable\_alb\_access\_logs](#input\_enable\_alb\_access\_logs) | Enable KMS-encrypted CloudWatch access logging for module-managed or supplied Kubernetes ALBs. | `bool` | `false` | no |
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
| <a name="output_access_logs_delivery_ids"></a> [access\_logs\_delivery\_ids](#output\_access\_logs\_delivery\_ids) | ALB CloudWatch log delivery IDs keyed by load-balancer name. |
| <a name="output_access_logs_kms_key_arn"></a> [access\_logs\_kms\_key\_arn](#output\_access\_logs\_kms\_key\_arn) | KMS key encrypting ALB access logs, or null when disabled. |
| <a name="output_access_logs_log_group_arn"></a> [access\_logs\_log\_group\_arn](#output\_access\_logs\_log\_group\_arn) | ARN of the CloudWatch ALB access-log group, or null when disabled. |
| <a name="output_access_logs_log_group_name"></a> [access\_logs\_log\_group\_name](#output\_access\_logs\_log\_group\_name) | CloudWatch log group receiving ALB access logs, or null when disabled. |
| <a name="output_access_logs_s3_bucket_name"></a> [access\_logs\_s3\_bucket\_name](#output\_access\_logs\_s3\_bucket\_name) | SSE-S3 bucket name for ALB access logs. |
| <a name="output_access_logs_s3_ingress_annotations"></a> [access\_logs\_s3\_ingress\_annotations](#output\_access\_logs\_s3\_ingress\_annotations) | Apply to an Ingress in each controller-managed ALB group; merge with existing load-balancer attributes. |
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