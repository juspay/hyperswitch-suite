# composition/s3

Creates an S3 bucket using the registry module
[`terraform-aws-modules/s3-bucket/aws`](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws)
(`~> 5.0`). When `enable_replication` is set, it also creates a replica bucket in a
different region and wires up cross-region replication (CRR) from the source bucket:
versioning is forced on both buckets, an IAM replication role is created, and a
replication rule is attached to the source bucket.

The replica bucket is provisioned through the module's own `aws.replica` provider
alias, whose region comes from `replica_region`. The default (source-region)
provider is supplied by the consuming layer (for Terragrunt roots, the generated
`provider.tf` from `root.hcl`).

## Example

```hcl
module "payment_files" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/s3?ref=s3-v0.1.0"

  environment        = "sandbox"
  region             = "ap-south-1"
  source_bucket_name = "hyperswitch-sandbox-payment-files"

  enable_replication  = true
  replica_region      = "ap-south-2"
  replica_bucket_name = "hyperswitch-sandbox-payment-files-replica"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.2 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_replica_bucket"></a> [replica\_bucket](#module\_replica\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 5.0 |
| <a name="module_source_bucket"></a> [source\_bucket](#module\_source\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [terraform_data.replication_guard](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_iam_policy_document.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.replication_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_replication"></a> [enable\_replication](#input\_enable\_replication) | Whether to create a replica bucket in a different region and configure cross-region replication from the source bucket. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/sandbox/prod) | `string` | n/a | yes |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow deleting non-empty buckets on destroy (applies to both source and replica) | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional KMS key ARN for SSE-KMS on the buckets. When null, SSE-S3 (AES256) is used. | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Primary (source) region. The source bucket is created with the default aws provider, which must be configured for this region. | `string` | n/a | yes |
| <a name="input_replica_bucket_name"></a> [replica\_bucket\_name](#input\_replica\_bucket\_name) | Name of the replica S3 bucket. Required when enable\_replication is true. | `string` | `null` | no |
| <a name="input_replica_region"></a> [replica\_region](#input\_replica\_region) | Region for the replica bucket. Required when enable\_replication is true. | `string` | `null` | no |
| <a name="input_replica_storage_class"></a> [replica\_storage\_class](#input\_replica\_storage\_class) | Storage class for replicated objects in the replica bucket | `string` | `"STANDARD"` | no |
| <a name="input_replication_rule_id"></a> [replication\_rule\_id](#input\_replication\_rule\_id) | ID for the replication rule | `string` | `"replicate-all"` | no |
| <a name="input_source_bucket_name"></a> [source\_bucket\_name](#input\_source\_bucket\_name) | Name of the source S3 bucket to create | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Enable versioning on the source bucket. Forced to true when enable\_replication is true, since cross-region replication requires versioning. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_replica_bucket_arn"></a> [replica\_bucket\_arn](#output\_replica\_bucket\_arn) | ARN of the replica bucket (null when replication is disabled) |
| <a name="output_replica_bucket_id"></a> [replica\_bucket\_id](#output\_replica\_bucket\_id) | Name/ID of the replica bucket (null when replication is disabled) |
| <a name="output_replication_enabled"></a> [replication\_enabled](#output\_replication\_enabled) | Whether cross-region replication is configured |
| <a name="output_replication_role_arn"></a> [replication\_role\_arn](#output\_replication\_role\_arn) | ARN of the IAM role used for replication (null when replication is disabled) |
| <a name="output_source_bucket_arn"></a> [source\_bucket\_arn](#output\_source\_bucket\_arn) | ARN of the source bucket |
| <a name="output_source_bucket_id"></a> [source\_bucket\_id](#output\_source\_bucket\_id) | Name/ID of the source bucket |
| <a name="output_source_bucket_regional_domain_name"></a> [source\_bucket\_regional\_domain\_name](#output\_source\_bucket\_regional\_domain\_name) | Region-specific domain name of the source bucket |
<!-- END_TF_DOCS -->
