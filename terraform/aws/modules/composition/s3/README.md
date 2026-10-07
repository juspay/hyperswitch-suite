# composition/s3

Creates an S3 bucket using the registry module
[`terraform-aws-modules/s3-bucket/aws`](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws)
(`~> 5.0`). When `replication_configuration.enabled` is set, it also creates a
replica bucket in a different region and wires up cross-region replication (CRR)
from the source bucket: versioning is forced on both buckets, an IAM replication
role is created, and a replication rule is attached to the source bucket.

KMS is regional, so the source and replica buckets take their own key ARNs
(`kms_key_arn` and `replication_configuration.kms_key_arn`). When the source is
KMS-encrypted, the replication rule opts SSE-KMS objects into replication, sets the
replica key on the destination, and the replication role is granted
decrypt/encrypt on the respective keys.

The replica bucket is provisioned through the module's own `aws.replica` provider
alias, whose region comes from `replication_configuration.region`. The default
(source-region) provider is supplied by the consuming layer (for Terragrunt roots,
the generated `provider.tf` from `root.hcl`).

## Example

```hcl
module "payment_files" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/s3?ref=s3-v0.1.0"

  environment = "sandbox"
  region      = "ap-south-1"
  bucket_name = "hyperswitch-sandbox-payment-files" # optional; derived when omitted

  replication_configuration = {
    enabled     = true
    region      = "ap-south-2"
    bucket_name = "hyperswitch-sandbox-payment-files-replica" # optional; derived when omitted
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
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
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/sandbox/prod) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Primary (source) region. The source bucket is created with the default aws provider, which must be configured for this region. | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the source S3 bucket. When null, it is derived as "<project\_name>-<environment>-<region>". | `string` | `null` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow deleting non-empty buckets on destroy (applies to both source and replica) | `bool` | `false` | no |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Enable versioning on the source bucket. Forced to true when replication is enabled, since cross-region replication requires versioning. | `bool` | `true` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional KMS key ARN (in the source region) for SSE-KMS on the source bucket. When null, SSE-S3 (AES256) is used. | `string` | `null` | no |
| <a name="input_replication_configuration"></a> [replication\_configuration](#input\_replication\_configuration) | Cross-region replication configuration (enabled / region / bucket\_name / storage\_class / kms\_key\_arn / rule\_id). | <pre>object({<br/>    enabled       = optional(bool, false)<br/>    region        = optional(string)<br/>    bucket_name   = optional(string)<br/>    storage_class = optional(string, "STANDARD")<br/>    kms_key_arn   = optional(string)<br/>    rule_id       = optional(string, "replicate-all")<br/>  })</pre> | `{}` | no |

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
