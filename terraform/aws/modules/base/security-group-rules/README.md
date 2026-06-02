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
| [aws_security_group_rule.rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_rules"></a> [rules](#input\_rules) | Security group rules. The 'source' field can be either CIDR blocks (list) or Security Group ID (string) | <pre>list(object({<br/>    type        = string # "ingress" or "egress"<br/>    description = string<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    cidr      = optional (list(string))    # Can be list(string) for CIDRs OR string for SG ID<br/>    sg_id     = optional (list(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | The security group ID to attach the rules to | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_rule_ids"></a> [rule\_ids](#output\_rule\_ids) | Map of rule indices to their IDs |
| <a name="output_rules_count"></a> [rules\_count](#output\_rules\_count) | Number of security group rules created |
<!-- END_TF_DOCS -->