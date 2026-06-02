<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_deregistration_delay"></a> [deregistration\_delay](#input\_deregistration\_delay) | Time in seconds for target deregistration | `number` | `300` | no |
| <a name="input_health_check"></a> [health\_check](#input\_health\_check) | Health check configuration | <pre>object({<br/>    enabled             = optional(bool, true)<br/>    healthy_threshold   = optional(number, 3)<br/>    unhealthy_threshold = optional(number, 3)<br/>    timeout             = optional(number, 10)<br/>    interval            = optional(number, 30)<br/>    port                = optional(string, "traffic-port")<br/>    protocol            = optional(string, "TCP")<br/>    path                = optional(string, null)<br/>    matcher             = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": true,<br/>  "healthy_threshold": 3,<br/>  "interval": 30,<br/>  "port": "traffic-port",<br/>  "protocol": "TCP",<br/>  "timeout": 10,<br/>  "unhealthy_threshold": 3<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the target group | `string` | n/a | yes |
| <a name="input_port"></a> [port](#input\_port) | Port on which targets receive traffic | `number` | n/a | yes |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | Protocol to use for routing traffic to the targets | `string` | `"TCP"` | no |
| <a name="input_stickiness"></a> [stickiness](#input\_stickiness) | Stickiness configuration | <pre>object({<br/>    enabled         = optional(bool, false)<br/>    type            = optional(string, "lb_cookie")<br/>    cookie_duration = optional(number, 86400)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to the target group | `map(string)` | `{}` | no |
| <a name="input_target_type"></a> [target\_type](#input\_target\_type) | Type of target (instance, ip, lambda, alb) | `string` | `"instance"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the target group will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_tg_arn"></a> [tg\_arn](#output\_tg\_arn) | The ARN of the target group |
| <a name="output_tg_arn_suffix"></a> [tg\_arn\_suffix](#output\_tg\_arn\_suffix) | The ARN suffix for use with CloudWatch metrics |
| <a name="output_tg_id"></a> [tg\_id](#output\_tg\_id) | The ID of the target group |
| <a name="output_tg_name"></a> [tg\_name](#output\_tg\_name) | The name of the target group |
| <a name="output_tg_port"></a> [tg\_port](#output\_tg\_port) | The port of the target group |
| <a name="output_tg_protocol"></a> [tg\_protocol](#output\_tg\_protocol) | The protocol of the target group |
<!-- END_TF_DOCS -->