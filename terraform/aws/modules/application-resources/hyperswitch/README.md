<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-aws-modules/kms/aws | 4.2.0 |
| <a name="module_s3_dashboard_themes"></a> [s3\_dashboard\_themes](#module\_s3\_dashboard\_themes) | terraform-aws-modules/s3-bucket/aws | ~> 5.0 |
| <a name="module_s3_file_uploads"></a> [s3\_file\_uploads](#module\_s3\_file\_uploads) | terraform-aws-modules/s3-bucket/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_dashboard_themes_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_file_uploads_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.secrets_manager_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ses_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.assume_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.kms_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_dashboard_themes_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_file_uploads_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.secrets_manager_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ses_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_openid_connect_provider.oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_kms_key.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_s3_bucket.dashboard_themes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_s3_bucket.file_uploads](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_assume_role_statements"></a> [additional\_assume\_role\_statements](#input\_additional\_assume\_role\_statements) | Additional IAM assume role policy statements to append | `list(any)` | `[]` | no |
| <a name="input_additional_iam_policies"></a> [additional\_iam\_policies](#input\_additional\_iam\_policies) | Map of additional IAM policies to create and attach to the IAM role. Each key is used as a policy name suffix. Value is an object with a `policy` field containing the IAM policy document as JSON string. | <pre>map(object({<br/>    policy = string # IAM policy document as JSON string<br/>  }))</pre> | `{}` | no |
| <a name="input_assume_role"></a> [assume\_role](#input\_assume\_role) | Cross-account assume role configuration. Set to {} to disable assume role policy. | <pre>object({<br/>    enabled          = optional(bool, false)<br/>    target_role_arns = optional(list(string), []) # List of role ARNs to allow assuming<br/>    account_id       = optional(string, null)     # Account ID for wildcard role assumption<br/>  })</pre> | `{}` | no |
| <a name="input_cluster_service_accounts"></a> [cluster\_service\_accounts](#input\_cluster\_service\_accounts) | Map of EKS cluster names to their respective list of Kubernetes service accounts (namespace and service account name) | <pre>map(list(object({<br/>    namespace = string<br/>    name      = string<br/>  })))</pre> | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/integ/prod) | `string` | n/a | yes |
| <a name="input_kms"></a> [kms](#input\_kms) | KMS key configuration. Set to {} to disable KMS key and policy. Set create=true to create key, or create=false with key\_arn to use existing key. Policy and tags are handled internally by the module. | <pre>object({<br/>    # Key source: either create new or use existing<br/>    create  = optional(bool, false)  # Set true to create KMS key, false to use existing<br/>    key_arn = optional(string, null) # Existing KMS key ARN (used when create=false)<br/><br/>    # Key creation settings (used when create=true)<br/>    description = optional(string, null)<br/>    multi_region = optional(bool, false)<br/><br/>    # Replica key settings<br/>    create_replica           = optional(bool, false)<br/>    create_replica_external  = optional(bool, false)<br/>    primary_key_arn          = optional(string, null)<br/>    primary_external_key_arn = optional(string, null)<br/><br/>    # External key settings<br/>    create_external       = optional(bool, false)<br/>    key_material_base64   = optional(string, null)<br/>    valid_to              = optional(string, null)<br/><br/>    # Key specifications<br/>    key_usage                = optional(string, null)<br/>    customer_master_key_spec = optional(string, null)<br/>    key_spec                 = optional(string, null)<br/>    deletion_window_in_days  = optional(number, null)<br/><br/>    # Key settings<br/>    is_enabled                         = optional(bool, null)<br/>    enable_key_rotation                = optional(bool, true)<br/>    rotation_period_in_days            = optional(number, null)<br/>    bypass_policy_lockout_safety_check = optional(bool, null)<br/><br/>    # Aliases<br/>    aliases                 = optional(list(string), [])<br/>    aliases_use_name_prefix = optional(bool, false)<br/><br/>    # Access control (for key policy)<br/>    key_administrators     = optional(list(string), [])<br/>    key_users              = optional(list(string), [])<br/>    key_service_users      = optional(list(string), [])<br/>    key_owners             = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_lambda"></a> [lambda](#input\_lambda) | Lambda function configuration. Set to {} to disable Lambda policy. Set enabled=true to allow Lambda operations on specific functions. | <pre>object({<br/>    enabled      = optional(bool, false)<br/>    function_arns = optional(list(string), []) # List of Lambda function ARNs to allow invoke/all operations on<br/>    # If empty list, only list/get/create permissions will be granted (no specific function access)<br/>  })</pre> | `{}` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_public_domain"></a> [public\_domain](#input\_public\_domain) | Public domain name to access hyperswitch | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for resource creation | `string` | `null` | no |
| <a name="input_s3_dashboard_themes"></a> [s3\_dashboard\_themes](#input\_s3\_dashboard\_themes) | S3 bucket configuration for dashboard themes. Set to {} to disable. Set create=true to create bucket, or create=false with bucket\_arn to use existing. | <pre>object({<br/>    create     = optional(bool, false)  # Set true to create S3 bucket, false to use existing<br/>    bucket_arn = optional(string, null) # Existing S3 bucket ARN (used when create=false)<br/><br/>    # Bucket creation settings (used when create=true)<br/>    bucket_name        = optional(string, null) # Auto-generated if not provided<br/>    force_destroy      = optional(bool, false)<br/>    versioning_enabled = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_s3_file_uploads"></a> [s3\_file\_uploads](#input\_s3\_file\_uploads) | S3 bucket configuration for file uploads. Set to {} to disable. Set create=true to create bucket, or create=false with bucket\_arn to use existing. | <pre>object({<br/>    create     = optional(bool, false)  # Set true to create S3 bucket, false to use existing<br/>    bucket_arn = optional(string, null) # Existing S3 bucket ARN (used when create=false)<br/><br/>    # Bucket creation settings (used when create=true)<br/>    bucket_name        = optional(string, null) # Auto-generated if not provided<br/>    force_destroy      = optional(bool, false)<br/>    versioning_enabled = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_secrets_manager"></a> [secrets\_manager](#input\_secrets\_manager) | Secrets Manager configuration. Set to {} to disable Secrets Manager policy. | <pre>object({<br/>    enabled    = optional(bool, false)<br/>    secret_arns = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_ses"></a> [ses](#input\_ses) | SES configuration. Set to {} to disable SES policy. Only accepts existing SES role ARN (does NOT create SES resources). | <pre>object({<br/>    enabled = optional(bool, false)  # Set true to enable SES policy<br/>    role_arn = optional(string, null) # Existing SES role ARN to assume<br/>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | AWS account ID |
| <a name="output_additional_iam_policies_arns"></a> [additional\_iam\_policies\_arns](#output\_additional\_iam\_policies\_arns) | Map of additional IAM policy ARNs (key = policy name suffix, value = ARN) |
| <a name="output_assume_role_enabled"></a> [assume\_role\_enabled](#output\_assume\_role\_enabled) | Whether cross-account assume role feature is enabled |
| <a name="output_assume_role_policy_arn"></a> [assume\_role\_policy\_arn](#output\_assume\_role\_policy\_arn) | ARN of the assume role IAM policy (if enabled) |
| <a name="output_kms_key_aliases"></a> [kms\_key\_aliases](#output\_kms\_key\_aliases) | Map of aliases created for the KMS key (only if created by this module) |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the KMS key (created or existing) |
| <a name="output_kms_key_enabled"></a> [kms\_key\_enabled](#output\_kms\_key\_enabled) | Whether KMS key feature is enabled |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ID of the created KMS key (only if created by this module) |
| <a name="output_kms_policy_arn"></a> [kms\_policy\_arn](#output\_kms\_policy\_arn) | ARN of the KMS IAM policy (if enabled) |
| <a name="output_lambda_enabled"></a> [lambda\_enabled](#output\_lambda\_enabled) | Whether Lambda feature is enabled |
| <a name="output_lambda_function_arns"></a> [lambda\_function\_arns](#output\_lambda\_function\_arns) | List of Lambda function ARNs configured for access |
| <a name="output_lambda_policy_arn"></a> [lambda\_policy\_arn](#output\_lambda\_policy\_arn) | ARN of the Lambda IAM policy (if enabled) |
| <a name="output_public_domain"></a> [public\_domain](#output\_public\_domain) | Public domain name to access hyperswitch |
| <a name="output_region"></a> [region](#output\_region) | AWS region where resources are created |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the IAM role for Hyperswitch application |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the IAM role for Hyperswitch application |
| <a name="output_s3_dashboard_themes_bucket_arn"></a> [s3\_dashboard\_themes\_bucket\_arn](#output\_s3\_dashboard\_themes\_bucket\_arn) | ARN of the dashboard themes S3 bucket (created or existing) |
| <a name="output_s3_dashboard_themes_bucket_name"></a> [s3\_dashboard\_themes\_bucket\_name](#output\_s3\_dashboard\_themes\_bucket\_name) | Name of the dashboard themes S3 bucket (only if created by this module) |
| <a name="output_s3_dashboard_themes_enabled"></a> [s3\_dashboard\_themes\_enabled](#output\_s3\_dashboard\_themes\_enabled) | Whether S3 dashboard themes feature is enabled |
| <a name="output_s3_dashboard_themes_policy_arn"></a> [s3\_dashboard\_themes\_policy\_arn](#output\_s3\_dashboard\_themes\_policy\_arn) | ARN of the dashboard themes S3 IAM policy (if enabled) |
| <a name="output_s3_file_uploads_bucket_arn"></a> [s3\_file\_uploads\_bucket\_arn](#output\_s3\_file\_uploads\_bucket\_arn) | ARN of the file uploads S3 bucket (created or existing) |
| <a name="output_s3_file_uploads_bucket_name"></a> [s3\_file\_uploads\_bucket\_name](#output\_s3\_file\_uploads\_bucket\_name) | Name of the file uploads S3 bucket (only if created by this module) |
| <a name="output_s3_file_uploads_enabled"></a> [s3\_file\_uploads\_enabled](#output\_s3\_file\_uploads\_enabled) | Whether S3 file uploads feature is enabled |
| <a name="output_s3_file_uploads_policy_arn"></a> [s3\_file\_uploads\_policy\_arn](#output\_s3\_file\_uploads\_policy\_arn) | ARN of the file uploads S3 IAM policy (if enabled) |
| <a name="output_secrets_manager_enabled"></a> [secrets\_manager\_enabled](#output\_secrets\_manager\_enabled) | Whether Secrets Manager feature is enabled |
| <a name="output_secrets_manager_policy_arn"></a> [secrets\_manager\_policy\_arn](#output\_secrets\_manager\_policy\_arn) | ARN of the Secrets Manager IAM policy (if enabled) |
| <a name="output_ses_enabled"></a> [ses\_enabled](#output\_ses\_enabled) | Whether SES feature is enabled |
| <a name="output_ses_policy_arn"></a> [ses\_policy\_arn](#output\_ses\_policy\_arn) | ARN of the SES IAM policy (if enabled) |
| <a name="output_ses_role_arn"></a> [ses\_role\_arn](#output\_ses\_role\_arn) | ARN of the SES role being assumed (if configured) |
<!-- END_TF_DOCS -->