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
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alpn_policy"></a> [alpn\_policy](#input\_alpn\_policy) | Name of the Application-Layer Protocol Negotiation (ALPN) policy | `string` | `null` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ARN of the default SSL server certificate (required for HTTPS/TLS) | `string` | `null` | no |
| <a name="input_default_action_type"></a> [default\_action\_type](#input\_default\_action\_type) | Type of default action (forward, redirect, fixed-response) | `string` | `"forward"` | no |
| <a name="input_fixed_response_config"></a> [fixed\_response\_config](#input\_fixed\_response\_config) | Fixed response configuration (used if default\_action\_type is 'fixed-response') | <pre>object({<br/>    content_type = optional(string, "text/plain")<br/>    message_body = optional(string, null)<br/>    status_code  = optional(string, "200")<br/>  })</pre> | <pre>{<br/>  "content_type": "text/plain",<br/>  "status_code": "200"<br/>}</pre> | no |
| <a name="input_load_balancer_arn"></a> [load\_balancer\_arn](#input\_load\_balancer\_arn) | ARN of the load balancer | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name identifier for the listener (used in tags) | `string` | n/a | yes |
| <a name="input_port"></a> [port](#input\_port) | Port on which the load balancer is listening | `number` | n/a | yes |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | Protocol for connections from clients to the load balancer | `string` | `"HTTP"` | no |
| <a name="input_redirect_config"></a> [redirect\_config](#input\_redirect\_config) | Redirect configuration (used if default\_action\_type is 'redirect') | <pre>object({<br/>    protocol    = optional(string, "#{protocol}")<br/>    port        = optional(string, "#{port}")<br/>    host        = optional(string, "#{host}")<br/>    path        = optional(string, "/#{path}")<br/>    query       = optional(string, "#{query}")<br/>    status_code = optional(string, "HTTP_301")<br/>  })</pre> | <pre>{<br/>  "host": "#{host}",<br/>  "path": "/#{path}",<br/>  "port": "#{port}",<br/>  "protocol": "#{protocol}",<br/>  "query": "#{query}",<br/>  "status_code": "HTTP_301"<br/>}</pre> | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | Name of the SSL Policy for the listener (required for HTTPS/TLS) | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to the listener | `map(string)` | `{}` | no |
| <a name="input_target_group_arn"></a> [target\_group\_arn](#input\_target\_group\_arn) | ARN of the target group (required if default\_action\_type is 'forward') | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_listener_arn"></a> [listener\_arn](#output\_listener\_arn) | ARN of the listener |
| <a name="output_listener_id"></a> [listener\_id](#output\_listener\_id) | ID of the listener |
| <a name="output_listener_port"></a> [listener\_port](#output\_listener\_port) | Port of the listener |
| <a name="output_listener_protocol"></a> [listener\_protocol](#output\_listener\_protocol) | Protocol of the listener |
<!-- END_TF_DOCS -->