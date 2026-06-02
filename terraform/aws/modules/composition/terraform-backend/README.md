<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_lock_table"></a> [lock\_table](#module\_lock\_table) | ../../base/dynamodb-table | n/a |
| <a name="module_state_bucket"></a> [state\_bucket](#module\_state\_bucket) | ../../base/s3-bucket | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket_policy.enforce_tls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allow_destroy"></a> [allow\_destroy](#input\_allow\_destroy) | Allow destruction of the bucket (should be false for prod) | `bool` | `false` | no |
| <a name="input_dynamodb_billing_mode"></a> [dynamodb\_billing\_mode](#input\_dynamodb\_billing\_mode) | Billing mode for DynamoDB (PROVISIONED or PAY\_PER\_REQUEST) | `string` | `"PAY_PER_REQUEST"` | no |
| <a name="input_dynamodb_kms_key_arn"></a> [dynamodb\_kms\_key\_arn](#input\_dynamodb\_kms\_key\_arn) | ARN of KMS key for DynamoDB encryption (null uses AWS managed key) | `string` | `null` | no |
| <a name="input_dynamodb_read_capacity"></a> [dynamodb\_read\_capacity](#input\_dynamodb\_read\_capacity) | Read capacity units for DynamoDB (only used with PROVISIONED billing) | `number` | `5` | no |
| <a name="input_dynamodb_table_name"></a> [dynamodb\_table\_name](#input\_dynamodb\_table\_name) | Name of the DynamoDB table for state locking | `string` | n/a | yes |
| <a name="input_dynamodb_write_capacity"></a> [dynamodb\_write\_capacity](#input\_dynamodb\_write\_capacity) | Write capacity units for DynamoDB (only used with PROVISIONED billing) | `number` | `5` | no |
| <a name="input_enable_dynamodb_pitr"></a> [enable\_dynamodb\_pitr](#input\_enable\_dynamodb\_pitr) | Enable point-in-time recovery for DynamoDB table | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id) | KMS key ID for S3 encryption (required if sse\_algorithm is aws:kms) | `string` | `null` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | List of lifecycle rules for the state bucket | <pre>list(object({<br/>    id                            = string<br/>    enabled                       = bool<br/>    prefix                        = optional(string, "")<br/>    expiration_days               = optional(number, null)<br/>    noncurrent_version_expiration = optional(number, null)<br/>    transition = optional(list(object({<br/>      days          = number<br/>      storage_class = string<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for tagging and naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_sse_algorithm"></a> [sse\_algorithm](#input\_sse\_algorithm) | Server-side encryption algorithm for S3 (AES256 or aws:kms) | `string` | `"AES256"` | no |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Name of the S3 bucket for Terraform state (must be globally unique) | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backend_config"></a> [backend\_config](#output\_backend\_config) | Backend configuration object for use in other Terraform deployments |
| <a name="output_backend_config_formatted"></a> [backend\_config\_formatted](#output\_backend\_config\_formatted) | Formatted backend configuration for copy-paste into backend.tf files |
| <a name="output_lock_table_arn"></a> [lock\_table\_arn](#output\_lock\_table\_arn) | The ARN of the lock table |
| <a name="output_lock_table_id"></a> [lock\_table\_id](#output\_lock\_table\_id) | The ID (name) of the lock table |
| <a name="output_lock_table_name"></a> [lock\_table\_name](#output\_lock\_table\_name) | The name of the lock table |
| <a name="output_state_bucket_arn"></a> [state\_bucket\_arn](#output\_state\_bucket\_arn) | The ARN of the state bucket |
| <a name="output_state_bucket_id"></a> [state\_bucket\_id](#output\_state\_bucket\_id) | The ID (name) of the state bucket |
| <a name="output_state_bucket_region"></a> [state\_bucket\_region](#output\_state\_bucket\_region) | The region of the state bucket |
<!-- END_TF_DOCS -->