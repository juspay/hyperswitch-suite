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
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID to use for instances | `string` | n/a | yes |
| <a name="input_block_device_mappings"></a> [block\_device\_mappings](#input\_block\_device\_mappings) | Block device mappings | <pre>list(object({<br/>    device_name = string<br/>    ebs = optional(object({<br/>      volume_size           = number<br/>      volume_type           = optional(string, "gp3")<br/>      iops                  = optional(number, null)<br/>      throughput            = optional(number, null)<br/>      delete_on_termination = optional(bool, true)<br/>      encrypted             = optional(bool, true)<br/>      kms_key_id            = optional(string, null)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the launch template | `string` | `"Managed by Terraform"` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | Whether the instance is EBS optimized | `bool` | `true` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Enable detailed monitoring | `bool` | `true` | no |
| <a name="input_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#input\_iam\_instance\_profile\_arn) | ARN of the IAM instance profile | `string` | `null` | no |
| <a name="input_iam_instance_profile_name"></a> [iam\_instance\_profile\_name](#input\_iam\_instance\_profile\_name) | Name of the IAM instance profile | `string` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type | `string` | n/a | yes |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Key pair name for SSH access | `string` | `null` | no |
| <a name="input_metadata_options"></a> [metadata\_options](#input\_metadata\_options) | Metadata options for the instance | <pre>object({<br/>    http_endpoint               = optional(string, "enabled")<br/>    http_tokens                 = optional(string, "required")<br/>    http_put_response_hop_limit = optional(number, 1)<br/>    instance_metadata_tags      = optional(string, "disabled")<br/>  })</pre> | <pre>{<br/>  "http_endpoint": "enabled",<br/>  "http_put_response_hop_limit": 1,<br/>  "http_tokens": "required"<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix for the launch template | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security group IDs | `list(string)` | `[]` | no |
| <a name="input_tag_specifications"></a> [tag\_specifications](#input\_tag\_specifications) | Tag specifications for resources created by instances | <pre>list(object({<br/>    resource_type = string<br/>    tags          = map(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to the launch template | `map(string)` | `{}` | no |
| <a name="input_update_default_version"></a> [update\_default\_version](#input\_update\_default\_version) | Whether to update the default version on each update | `bool` | `true` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | User data script (will be base64 encoded) | `string` | `""` | no |
| <a name="input_user_data_base64"></a> [user\_data\_base64](#input\_user\_data\_base64) | Base64 encoded user data (use this if already encoded) | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_lt_arn"></a> [lt\_arn](#output\_lt\_arn) | The ARN of the launch template |
| <a name="output_lt_default_version"></a> [lt\_default\_version](#output\_lt\_default\_version) | The default version of the launch template |
| <a name="output_lt_id"></a> [lt\_id](#output\_lt\_id) | The ID of the launch template |
| <a name="output_lt_latest_version"></a> [lt\_latest\_version](#output\_lt\_latest\_version) | The latest version of the launch template |
| <a name="output_lt_name"></a> [lt\_name](#output\_lt\_name) | The name of the launch template |
<!-- END_TF_DOCS -->