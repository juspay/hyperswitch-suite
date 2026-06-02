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
| [aws_network_acl.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules) | List of egress rules | <pre>list(object({<br/>    rule_number     = number<br/>    protocol        = string<br/>    rule_action     = string<br/>    cidr_block      = optional(string)<br/>    ipv6_cidr_block = optional(string)<br/>    from_port       = optional(number)<br/>    to_port         = optional(number)<br/>    icmp_type       = optional(number)<br/>    icmp_code       = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | List of ingress rules | <pre>list(object({<br/>    rule_number     = number<br/>    protocol        = string<br/>    rule_action     = string<br/>    cidr_block      = optional(string)<br/>    ipv6_cidr_block = optional(string)<br/>    from_port       = optional(number)<br/>    to_port         = optional(number)<br/>    icmp_type       = optional(number)<br/>    icmp_code       = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_nacl_name"></a> [nacl\_name](#input\_nacl\_name) | Name of the network ACL | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs to associate with this NACL | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_nacl_arn"></a> [nacl\_arn](#output\_nacl\_arn) | The ARN of the network ACL |
| <a name="output_nacl_id"></a> [nacl\_id](#output\_nacl\_id) | The ID of the network ACL |
| <a name="output_nacl_owner_id"></a> [nacl\_owner\_id](#output\_nacl\_owner\_id) | The ID of the AWS account that owns the network ACL |
<!-- END_TF_DOCS -->