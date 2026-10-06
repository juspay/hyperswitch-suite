# s3-bucket (base)

Base module for a single S3 bucket: public-access block, SSE (AES256 or SSE-KMS),
versioning, lifecycle rules, and (optionally) a replication configuration plus the
IAM role S3 assumes for it. With `create_bucket = false` the module can attach
replication to a **pre-existing, already-versioned** bucket without managing the
bucket itself.

## Usage

Create and manage a bucket:

```hcl
module "data" {
  source = "../../base/s3-bucket"

  bucket_name       = "my-app-data"
  enable_versioning = true
  versioning_status = "Enabled"
  sse_algorithm     = "AES256"

  tags = { Environment = "prod" }
}
```

Attach replication to an existing (already versioned) bucket, with the role's
object permissions scoped to a prefix:

```hcl
module "data_replication" {
  source = "../../base/s3-bucket"

  bucket_name   = "my-app-data"   # existing bucket
  create_bucket = false

  enable_replication      = true
  create_replication_role = true

  replication_rules = [{
    id                     = "crr"
    prefix                 = "incoming/"      # null = whole bucket
    destination_bucket_arn = "arn:aws:s3:::my-app-data-replica"
  }]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.replication_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_block_public_acls"></a> [block\_public\_acls](#input\_block\_public\_acls) | Block public ACLs | `bool` | `true` | no |
| <a name="input_block_public_policy"></a> [block\_public\_policy](#input\_block\_public\_policy) | Block public bucket policies | `bool` | `true` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket | `string` | n/a | yes |
| <a name="input_create_bucket"></a> [create\_bucket](#input\_create\_bucket) | Whether to create the bucket. Set false to manage replication on a pre-existing bucket (which must already be versioned) without creating/managing the bucket itself. | `bool` | `true` | no |
| <a name="input_create_replication_role"></a> [create\_replication\_role](#input\_create\_replication\_role) | Create the IAM role S3 assumes to replicate FROM this bucket, derived from replication\_rules (source = this bucket, destinations = the rules' buckets, object perms scoped to each rule's prefix). When false, pass replication\_role\_arn. | `bool` | `false` | no |
| <a name="input_enable_replication"></a> [enable\_replication](#input\_enable\_replication) | Enable S3 replication configuration on this (source) bucket. Requires versioning to be enabled. | `bool` | `false` | no |
| <a name="input_enable_versioning"></a> [enable\_versioning](#input\_enable\_versioning) | Enable versioning for the bucket | `bool` | `false` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Whether to allow bucket deletion with objects in it | `bool` | `false` | no |
| <a name="input_ignore_public_acls"></a> [ignore\_public\_acls](#input\_ignore\_public\_acls) | Ignore public ACLs | `bool` | `true` | no |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id) | KMS key ID for encryption (required if sse\_algorithm is aws:kms) | `string` | `null` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | List of lifecycle rules | <pre>list(object({<br/>    id                            = string<br/>    enabled                       = bool<br/>    prefix                        = optional(string, "")<br/>    expiration_days               = optional(number, null)<br/>    noncurrent_version_expiration = optional(number, null)<br/>    transition = optional(list(object({<br/>      days          = number<br/>      storage_class = string<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_replication_role_arn"></a> [replication\_role\_arn](#input\_replication\_role\_arn) | ARN of an existing IAM role S3 assumes to replicate objects. Required when enable\_replication is true and create\_replication\_role is false. | `string` | `null` | no |
| <a name="input_replication_role_name"></a> [replication\_role\_name](#input\_replication\_role\_name) | Name for the replication role when create\_replication\_role = true. Defaults to s3-crr-<bucket\_name>. | `string` | `null` | no |
| <a name="input_replication_rules"></a> [replication\_rules](#input\_replication\_rules) | List of replication rules applied when enable\_replication is true. | <pre>list(object({<br/>    id                        = string<br/>    status                    = optional(string, "Enabled")<br/>    priority                  = optional(number, 0)<br/>    prefix                    = optional(string, null)<br/>    destination_bucket_arn    = string<br/>    destination_storage_class = optional(string, "STANDARD")<br/>    replica_kms_key_id        = optional(string, null)<br/>    delete_marker_replication = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_restrict_public_buckets"></a> [restrict\_public\_buckets](#input\_restrict\_public\_buckets) | Restrict public bucket policies | `bool` | `true` | no |
| <a name="input_sse_algorithm"></a> [sse\_algorithm](#input\_sse\_algorithm) | Server-side encryption algorithm (AES256 or aws:kms) | `string` | `"AES256"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to the bucket | `map(string)` | `{}` | no |
| <a name="input_versioning_status"></a> [versioning\_status](#input\_versioning\_status) | Versioning status (Enabled, Suspended, Disabled) | `string` | `"Disabled"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | The ARN of the bucket |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | The bucket domain name (null when create\_bucket = false) |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | The ID (name) of the bucket |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | The name of the bucket (alias for bucket\_id) |
| <a name="output_bucket_region"></a> [bucket\_region](#output\_bucket\_region) | The AWS region of the bucket (null when create\_bucket = false) |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | The bucket regional domain name (null when create\_bucket = false) |
| <a name="output_replication_role_arn"></a> [replication\_role\_arn](#output\_replication\_role\_arn) | ARN of the replication role created when create\_replication\_role = true (else the passed-in replication\_role\_arn). |
<!-- END_TF_DOCS -->
