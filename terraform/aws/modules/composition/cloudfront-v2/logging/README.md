<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.20 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.20 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_canonical_user_id.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/canonical_user_id) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_block_public_access"></a> [block\_public\_access](#input\_block\_public\_access) | n/a | `bool` | `true` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | S3 bucket name for CloudFront logs (default: {project}-cf-logs-{region}-{env}) | `string` | `""` | no |
| <a name="input_create"></a> [create](#input\_create) | n/a | `bool` | `true` | no |
| <a name="input_enable_replication"></a> [enable\_replication](#input\_enable\_replication) | Enable cross-region replication | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow destruction of non-empty bucket | `bool` | `false` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key ID for SSE-KMS (leave empty for AES256) | `string` | `null` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | List of lifecycle rules for log objects | <pre>list(object({<br/>    id                                     = string<br/>    enabled                                = optional(bool, true)<br/>    prefix                                 = optional(string, "")<br/>    transition_to_ia_days                  = optional(number, 30)<br/>    transition_to_glacier_days             = optional(number, 90)<br/>    expiration_days                        = optional(number, 365)<br/>    noncurrent_version_transition_ia_days  = optional(number, 30)<br/>    noncurrent_version_transition_glacier_days = optional(number, 90)<br/>    noncurrent_version_expiration_days     = optional(number, 365)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "enabled": true,<br/>    "expiration_days": 365,<br/>    "id": "logs-lifecycle",<br/>    "noncurrent_version_expiration_days": 365,<br/>    "noncurrent_version_transition_glacier_days": 90,<br/>    "noncurrent_version_transition_ia_days": 30,<br/>    "prefix": "",<br/>    "transition_to_glacier_days": 90,<br/>    "transition_to_ia_days": 30<br/>  }<br/>]</pre> | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | n/a | `string` | `"hyperswitch"` | no |
| <a name="input_replication_role_arn"></a> [replication\_role\_arn](#input\_replication\_role\_arn) | IAM role ARN for replication | `string` | `null` | no |
| <a name="input_replication_storage_class"></a> [replication\_storage\_class](#input\_replication\_storage\_class) | Storage class for replicated objects | `string` | `"STANDARD_IA"` | no |
| <a name="input_replication_target_bucket_arn"></a> [replication\_target\_bucket\_arn](#input\_replication\_target\_bucket\_arn) | ARN of replication target bucket | `string` | `null` | no |
| <a name="input_sse_algorithm"></a> [sse\_algorithm](#input\_sse\_algorithm) | Server-side encryption algorithm (AES256 or aws:kms) | `string` | `"AES256"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | n/a | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | S3 bucket ARN |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | S3 bucket domain name |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | S3 bucket name |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | S3 bucket regional domain name |
<!-- END_TF_DOCS -->