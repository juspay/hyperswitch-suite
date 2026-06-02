<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_external_jump_iam_role"></a> [external\_jump\_iam\_role](#module\_external\_jump\_iam\_role) | terraform-aws-modules/iam/aws//modules/iam-role | ~> 6.2 |
| <a name="module_external_jump_instance"></a> [external\_jump\_instance](#module\_external\_jump\_instance) | terraform-aws-modules/ec2-instance/aws | ~> 6.0 |
| <a name="module_external_jump_sg"></a> [external\_jump\_sg](#module\_external\_jump\_sg) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_internal_jump_iam_role"></a> [internal\_jump\_iam\_role](#module\_internal\_jump\_iam\_role) | terraform-aws-modules/iam/aws//modules/iam-role | ~> 6.2 |
| <a name="module_internal_jump_instance"></a> [internal\_jump\_instance](#module\_internal\_jump\_instance) | terraform-aws-modules/ec2-instance/aws | ~> 6.0 |
| <a name="module_internal_jump_sg"></a> [internal\_jump\_sg](#module\_internal\_jump\_sg) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_internal_jump_ssh_key_parameter"></a> [internal\_jump\_ssh\_key\_parameter](#module\_internal\_jump\_ssh\_key\_parameter) | terraform-aws-modules/ssm-parameter/aws | ~> 1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.jump_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_key_pair.internal_jump](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_security_group_rule.external_jump_default_egress_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.external_jump_default_egress_to_internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.internal_jump_default_ingress_from_external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [tls_private_key.internal_jump](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.amazon_linux_2023](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_internal_jump_ssm"></a> [enable\_internal\_jump\_ssm](#input\_enable\_internal\_jump\_ssm) | Enable SSM Session Manager access for internal jump host. When true, adds SSM policies to internal jump IAM role | `bool` | `false` | no |
| <a name="input_enable_migration_mode"></a> [enable\_migration\_mode](#input\_enable\_migration\_mode) | Enable SSM SendCommand permissions for Packer migration. Should be disabled after migration is complete for security. Only affects: ssm:DescribeInstanceInformation, ssm:SendCommand, ssm:GetCommandInvocation, ssm:ListCommandInvocations | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, integ, prod) | `string` | n/a | yes |
| <a name="input_external_jump_ami_id"></a> [external\_jump\_ami\_id](#input\_external\_jump\_ami\_id) | AMI ID for external jump host (defaults to latest Amazon Linux 2) | `string` | `null` | no |
| <a name="input_external_userdata_override"></a> [external\_userdata\_override](#input\_external\_userdata\_override) | Custom userdata script for external jump host. If set, replaces the default template entirely. | `string` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type for jump hosts | `string` | `"t3.micro"` | no |
| <a name="input_internal_jump_ami_id"></a> [internal\_jump\_ami\_id](#input\_internal\_jump\_ami\_id) | AMI ID for internal jump host (defaults to latest Amazon Linux 2) | `string` | `null` | no |
| <a name="input_internal_userdata_override"></a> [internal\_userdata\_override](#input\_internal\_userdata\_override) | Custom userdata script for internal jump host. If set, replaces the default template entirely. | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention in days | `number` | `30` | no |
| <a name="input_private_subnet_id"></a> [private\_subnet\_id](#input\_private\_subnet\_id) | Private subnet ID for internal jump host | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_public_subnet_id"></a> [public\_subnet\_id](#input\_public\_subnet\_id) | Public subnet ID for external jump host | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region where this resource will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size of the root volume in GiB | `number` | `20` | no |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | Type of the root volume | `string` | `"gp3"` | no |
| <a name="input_ssm_os_username"></a> [ssm\_os\_username](#input\_ssm\_os\_username) | OS username for SSM Session Manager access. Defaults to the standard username used by SSM Agent. Can be overridden based on your environment and SSM config. | `string` | `"ssm-user"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where jump hosts will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_groups"></a> [cloudwatch\_log\_groups](#output\_cloudwatch\_log\_groups) | Map of CloudWatch log group names |
| <a name="output_connection_guide"></a> [connection\_guide](#output\_connection\_guide) | Guide for connecting to jump hosts |
| <a name="output_external_iam_role_arn"></a> [external\_iam\_role\_arn](#output\_external\_iam\_role\_arn) | The ARN of the IAM role for external jump host |
| <a name="output_external_jump_instance_id"></a> [external\_jump\_instance\_id](#output\_external\_jump\_instance\_id) | The ID of the external jump host instance |
| <a name="output_external_jump_private_ip"></a> [external\_jump\_private\_ip](#output\_external\_jump\_private\_ip) | The private IP address of the external jump host |
| <a name="output_external_jump_public_ip"></a> [external\_jump\_public\_ip](#output\_external\_jump\_public\_ip) | The public IP address of the external jump host |
| <a name="output_external_jump_ssm_command"></a> [external\_jump\_ssm\_command](#output\_external\_jump\_ssm\_command) | AWS CLI command to connect to external jump host via Session Manager |
| <a name="output_external_security_group_id"></a> [external\_security\_group\_id](#output\_external\_security\_group\_id) | The ID of the external jump host security group |
| <a name="output_internal_iam_role_arn"></a> [internal\_iam\_role\_arn](#output\_internal\_iam\_role\_arn) | The ARN of the IAM role for internal jump host |
| <a name="output_internal_iam_role_name"></a> [internal\_iam\_role\_name](#output\_internal\_iam\_role\_name) | The name of the IAM role for internal jump host |
| <a name="output_internal_jump_instance_id"></a> [internal\_jump\_instance\_id](#output\_internal\_jump\_instance\_id) | The ID of the internal jump host instance |
| <a name="output_internal_jump_private_ip"></a> [internal\_jump\_private\_ip](#output\_internal\_jump\_private\_ip) | The private IP address of the internal jump host |
| <a name="output_internal_jump_ssh_key_retrieval_command"></a> [internal\_jump\_ssh\_key\_retrieval\_command](#output\_internal\_jump\_ssh\_key\_retrieval\_command) | Command to retrieve internal jump SSH private key |
| <a name="output_internal_jump_ssh_key_ssm_path"></a> [internal\_jump\_ssh\_key\_ssm\_path](#output\_internal\_jump\_ssh\_key\_ssm\_path) | SSM Parameter Store path for internal jump SSH private key |
| <a name="output_internal_jump_ssm_command"></a> [internal\_jump\_ssm\_command](#output\_internal\_jump\_ssm\_command) | AWS CLI command to connect to internal jump host via Session Manager |
| <a name="output_internal_security_group_id"></a> [internal\_security\_group\_id](#output\_internal\_security\_group\_id) | The ID of the internal jump host security group |
| <a name="output_migration_mode_status"></a> [migration\_mode\_status](#output\_migration\_mode\_status) | Current migration mode status for SSM SendCommand permissions |
<!-- END_TF_DOCS -->