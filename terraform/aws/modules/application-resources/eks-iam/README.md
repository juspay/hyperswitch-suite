<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.31.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 5.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.s3_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.customer_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Application name (e.g., hyperswitch, control-centre) | `string` | n/a | yes |
| <a name="input_assume_role_principals"></a> [assume\_role\_principals](#input\_assume\_role\_principals) | Cross-account assume role trust. type: AWS for IAM roles, Federated for federated identities, Service for AWS services | <pre>list(object({<br/>    type        = string<br/>    identifiers = list(string)<br/>  }))</pre> | `null` | no |
| <a name="input_aws_managed_policy_names"></a> [aws\_managed\_policy\_names](#input\_aws\_managed\_policy\_names) | List of AWS managed policy names to attach (e.g., AmazonEC2ContainerRegistryReadOnly) | `list(string)` | `[]` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_create_s3_bucket"></a> [create\_s3\_bucket](#input\_create\_s3\_bucket) | Whether to create an S3 bucket alongside the IAM role. Default is false. | `bool` | `false` | no |
| <a name="input_custom_trust_statements"></a> [custom\_trust\_statements](#input\_custom\_trust\_statements) | Custom trust statements for maximum flexibility. Allows any valid IAM trust policy statement (Service, AWS, Federated, etc.). Highest priority in trust policy. | `list(any)` | `[]` | no |
| <a name="input_customer_managed_policy_arns"></a> [customer\_managed\_policy\_arns](#input\_customer\_managed\_policy\_arns) | List of customer managed policy ARNs to attach (typically from shared-policies) | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_force_detach_policies"></a> [force\_detach\_policies](#input\_force\_detach\_policies) | Whether to force detaching policies when destroying the role | `bool` | `true` | no |
| <a name="input_inline_policies"></a> [inline\_policies](#input\_inline\_policies) | Map of inline policies for role-specific permissions. Use sparingly - prefer managed policies for reusability. | `map(string)` | `{}` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration for the role (in seconds) | `number` | `3600` | no |
| <a name="input_oidc_providers"></a> [oidc\_providers](#input\_oidc\_providers) | OIDC provider trust for EKS service accounts. Direct condition specification for maximum flexibility. Each condition becomes a separate statement in the trust policy. | <pre>map(object({<br/>    provider_arn = string<br/>    conditions = list(object({<br/>      type   = string # "StringEquals" or "StringLike"<br/>      claim  = string # OIDC claim type (e.g., "sub", "aud")<br/>      values = list(string)<br/>    }))<br/>  }))</pre> | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Custom IAM role description | `string` | `null` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Custom IAM role name. If null, auto-generated as {project}-{env}-{app}-role | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | IAM role path | `string` | `"/"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Custom S3 bucket name. If null, auto-generated as {project}-{env}-{app}-storage | `string` | `null` | no |
| <a name="input_s3_enable_versioning"></a> [s3\_enable\_versioning](#input\_s3\_enable\_versioning) | Enable versioning for the S3 bucket | `bool` | `false` | no |
| <a name="input_s3_force_destroy"></a> [s3\_force\_destroy](#input\_s3\_force\_destroy) | Whether to allow S3 bucket deletion with objects in it | `bool` | `false` | no |
| <a name="input_s3_kms_master_key_id"></a> [s3\_kms\_master\_key\_id](#input\_s3\_kms\_master\_key\_id) | KMS key ID for S3 encryption (required if s3\_sse\_algorithm is aws:kms) | `string` | `null` | no |
| <a name="input_s3_lifecycle_rules"></a> [s3\_lifecycle\_rules](#input\_s3\_lifecycle\_rules) | List of lifecycle rules for the S3 bucket. See terraform-aws-modules/s3-bucket documentation for format. | `any` | `[]` | no |
| <a name="input_s3_permissions_policy"></a> [s3\_permissions\_policy](#input\_s3\_permissions\_policy) | JSON-encoded IAM policy granting S3 permissions for the created bucket. Will be attached as an inline policy named 's3-permissions'. Required if create\_s3\_bucket=true. | `string` | `null` | no |
| <a name="input_s3_server_access_logging"></a> [s3\_server\_access\_logging](#input\_s3\_server\_access\_logging) | S3 server access logging configuration. Set enabled=true to log all requests to the bucket. | <pre>object({<br/>    enabled       = bool<br/>    target_bucket = string<br/>    target_prefix = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "target_bucket": "",<br/>  "target_prefix": ""<br/>}</pre> | no |
| <a name="input_s3_sse_algorithm"></a> [s3\_sse\_algorithm](#input\_s3\_sse\_algorithm) | Server-side encryption algorithm for S3 bucket (AES256 or aws:kms) | `string` | `"AES256"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the created IAM role |
| <a name="output_role_id"></a> [role\_id](#output\_role\_id) | ID of the created IAM role |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the created IAM role |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | ARN of the created S3 bucket (null if not created) |
| <a name="output_s3_bucket_domain_name"></a> [s3\_bucket\_domain\_name](#output\_s3\_bucket\_domain\_name) | Domain name of the created S3 bucket (null if not created) |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Name of the created S3 bucket (null if not created) |
| <a name="output_s3_bucket_region"></a> [s3\_bucket\_region](#output\_s3\_bucket\_region) | AWS region of the created S3 bucket (null if not created) |
| <a name="output_s3_bucket_regional_domain_name"></a> [s3\_bucket\_regional\_domain\_name](#output\_s3\_bucket\_regional\_domain\_name) | Regional domain name of the created S3 bucket (null if not created) |
<!-- END_TF_DOCS -->