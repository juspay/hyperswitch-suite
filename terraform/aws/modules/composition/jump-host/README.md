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

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_jump_iam_role"></a> [jump\_iam\_role](#module\_jump\_iam\_role) | terraform-aws-modules/iam/aws//modules/iam-role | ~> 6.2 |
| <a name="module_jump_instance"></a> [jump\_instance](#module\_jump\_instance) | terraform-aws-modules/ec2-instance/aws | ~> 6.0 |
| <a name="module_jump_sg"></a> [jump\_sg](#module\_jump\_sg) | terraform-aws-modules/security-group/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.jump_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.ssm_session_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_s3_bucket.ssm_session_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.ssm_session_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_public_access_block.ssm_session_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.ssm_session_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.ssm_session_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_ssm_document.session_preferences](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ami.amazon_linux_2023](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID for generic jump host (defaults to latest Amazon Linux 2023) | `string` | `null` | no |
| <a name="input_create_ssm_cloudwatch_log_group"></a> [create\_ssm\_cloudwatch\_log\_group](#input\_create\_ssm\_cloudwatch\_log\_group) | Whether to create a CloudWatch log group for SSM session logs. | `bool` | `false` | no |
| <a name="input_create_ssm_s3_bucket"></a> [create\_ssm\_s3\_bucket](#input\_create\_ssm\_s3\_bucket) | Whether to create an S3 bucket for SSM session logs. | `bool` | `false` | no |
| <a name="input_create_ssm_session_preferences"></a> [create\_ssm\_session\_preferences](#input\_create\_ssm\_session\_preferences) | Whether to create the SSM Session Manager preferences document. Set to false if another environment in the same AWS account already manages this account-level setting. | `bool` | `true` | no |
| <a name="input_enable_migration_mode"></a> [enable\_migration\_mode](#input\_enable\_migration\_mode) | Enable SSM SendCommand permissions for Packer migration. Should be disabled after migration is complete for security. | `bool` | `false` | no |
| <a name="input_enable_ssm_session_encryption"></a> [enable\_ssm\_session\_encryption](#input\_enable\_ssm\_session\_encryption) | Enable KMS encryption for SSM Session Manager sessions | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, integ, prod) | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type for jump host | `string` | `"t3.micro"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention in days | `number` | `30` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region where this resource will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size of the root volume in GiB | `number` | `20` | no |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | Type of the root volume | `string` | `"gp3"` | no |
| <a name="input_ssm_cloudwatch_log_group_name"></a> [ssm\_cloudwatch\_log\_group\_name](#input\_ssm\_cloudwatch\_log\_group\_name) | CloudWatch log group name for SSM session logs. Required when ssm\_cloudwatch\_logging\_enabled=true and create\_ssm\_cloudwatch\_log\_group=false. Ignored when create\_ssm\_cloudwatch\_log\_group=true. | `string` | `""` | no |
| <a name="input_ssm_cloudwatch_log_group_name_prefix"></a> [ssm\_cloudwatch\_log\_group\_name\_prefix](#input\_ssm\_cloudwatch\_log\_group\_name\_prefix) | Name prefix for the SSM CloudWatch log group. Only used when create\_ssm\_cloudwatch\_log\_group=true. | `string` | `"/aws/ssm/session-logs"` | no |
| <a name="input_ssm_cloudwatch_log_group_retention_days"></a> [ssm\_cloudwatch\_log\_group\_retention\_days](#input\_ssm\_cloudwatch\_log\_group\_retention\_days) | CloudWatch log retention in days for SSM session logs. Only used when create\_ssm\_cloudwatch\_log\_group=true. | `number` | `90` | no |
| <a name="input_ssm_cloudwatch_logging_enabled"></a> [ssm\_cloudwatch\_logging\_enabled](#input\_ssm\_cloudwatch\_logging\_enabled) | Enable CloudWatch logging for SSM sessions | `bool` | `true` | no |
| <a name="input_ssm_idle_session_timeout"></a> [ssm\_idle\_session\_timeout](#input\_ssm\_idle\_session\_timeout) | Idle session timeout in minutes. Session terminates after this period of inactivity. | `number` | `10` | no |
| <a name="input_ssm_max_session_duration"></a> [ssm\_max\_session\_duration](#input\_ssm\_max\_session\_duration) | Maximum session duration in minutes. Leave empty string for unlimited. | `string` | `""` | no |
| <a name="input_ssm_run_as_user"></a> [ssm\_run\_as\_user](#input\_ssm\_run\_as\_user) | Default OS user to run sessions as (e.g., 'ubuntu'). When set, SSM creates OS users based on IAM user name and runs sessions as that user. Leave empty to disable run-as functionality (uses ssm-user). | `string` | `""` | no |
| <a name="input_ssm_s3_bucket_lifecycle_days"></a> [ssm\_s3\_bucket\_lifecycle\_days](#input\_ssm\_s3\_bucket\_lifecycle\_days) | Number of days before transitioning objects to Glacier. Set to 0 to disable lifecycle rules. | `number` | `90` | no |
| <a name="input_ssm_s3_bucket_name"></a> [ssm\_s3\_bucket\_name](#input\_ssm\_s3\_bucket\_name) | S3 bucket name for SSM session logs. Required when ssm\_s3\_logging\_enabled=true and create\_ssm\_s3\_bucket=false. | `string` | `""` | no |
| <a name="input_ssm_s3_bucket_name_prefix"></a> [ssm\_s3\_bucket\_name\_prefix](#input\_ssm\_s3\_bucket\_name\_prefix) | Name prefix for the SSM S3 bucket. Only used when create\_ssm\_s3\_bucket=true. | `string` | `"ssm-session-logs"` | no |
| <a name="input_ssm_s3_bucket_versioning"></a> [ssm\_s3\_bucket\_versioning](#input\_ssm\_s3\_bucket\_versioning) | Enable versioning for the SSM S3 bucket. | `bool` | `true` | no |
| <a name="input_ssm_s3_key_prefix"></a> [ssm\_s3\_key\_prefix](#input\_ssm\_s3\_key\_prefix) | S3 key prefix for SSM session logs | `string` | `"session-manager"` | no |
| <a name="input_ssm_s3_logging_enabled"></a> [ssm\_s3\_logging\_enabled](#input\_ssm\_s3\_logging\_enabled) | Enable S3 logging for SSM sessions | `bool` | `false` | no |
| <a name="input_ssm_shell_profile_linux"></a> [ssm\_shell\_profile\_linux](#input\_ssm\_shell\_profile\_linux) | Linux shell profile for SSM sessions. Runs when session starts. | `string` | `""` | no |
| <a name="input_ssm_shell_profile_windows"></a> [ssm\_shell\_profile\_windows](#input\_ssm\_shell\_profile\_windows) | Windows shell profile for SSM sessions. | `string` | `""` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for the generic jump host (typically a private subnet) | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where jump host will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group for jump host logs |
| <a name="output_connection_guide"></a> [connection\_guide](#output\_connection\_guide) | Guide for connecting to the generic jump host |
| <a name="output_deployment_mode"></a> [deployment\_mode](#output\_deployment\_mode) | Current deployment mode - always 'generic' for this module |
| <a name="output_jump_iam_role_arn"></a> [jump\_iam\_role\_arn](#output\_jump\_iam\_role\_arn) | The ARN of the IAM role for the generic jump host |
| <a name="output_jump_iam_role_name"></a> [jump\_iam\_role\_name](#output\_jump\_iam\_role\_name) | The name of the IAM role for the generic jump host |
| <a name="output_jump_instance_id"></a> [jump\_instance\_id](#output\_jump\_instance\_id) | The ID of the generic jump host instance |
| <a name="output_jump_private_ip"></a> [jump\_private\_ip](#output\_jump\_private\_ip) | The private IP address of the generic jump host |
| <a name="output_jump_security_group_id"></a> [jump\_security\_group\_id](#output\_jump\_security\_group\_id) | The ID of the generic jump host security group |
| <a name="output_jump_ssm_command"></a> [jump\_ssm\_command](#output\_jump\_ssm\_command) | AWS CLI command to connect to jump host via Session Manager |
| <a name="output_migration_mode_status"></a> [migration\_mode\_status](#output\_migration\_mode\_status) | Current migration mode status for SSM SendCommand permissions |
| <a name="output_ssm_cloudwatch_log_group_arn"></a> [ssm\_cloudwatch\_log\_group\_arn](#output\_ssm\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch log group for SSM session logs (null when not created by this module) |
| <a name="output_ssm_cloudwatch_log_group_name"></a> [ssm\_cloudwatch\_log\_group\_name](#output\_ssm\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group for SSM session logs (null when not created) |
| <a name="output_ssm_s3_bucket_arn"></a> [ssm\_s3\_bucket\_arn](#output\_ssm\_s3\_bucket\_arn) | ARN of the S3 bucket for SSM session logs (null when not created by this module) |
| <a name="output_ssm_s3_bucket_name"></a> [ssm\_s3\_bucket\_name](#output\_ssm\_s3\_bucket\_name) | Name of the S3 bucket for SSM session logs (null when not enabled) |
| <a name="output_ssm_session_preferences_document"></a> [ssm\_session\_preferences\_document](#output\_ssm\_session\_preferences\_document) | Name of the SSM Session Manager preferences document (null when not created) |
<!-- END_TF_DOCS -->