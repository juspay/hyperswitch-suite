# s3-bucket-replication

Glue module for same-account **S3 Cross-Region Replication**. It wires two
`base/s3-bucket` instances across two regions — a destination (replica) bucket via
the `aws.replica` provider, and the source bucket whose replication rule + IAM role
(both produced by `base/s3-bucket`) point at it. **No replication logic lives here** —
it's in `base/s3-bucket`.

The caller passes two providers:

```hcl
module "crr" {
  source    = "../../modules/composition/s3-bucket-replication"
  providers = { aws = aws, aws.replica = aws.replica }

  source_bucket_name      = "my-app-data"
  destination_bucket_name = "my-app-data-replica"

  # Retrofit onto an existing, already-versioned source bucket:
  create_source_bucket = false

  replication_prefix       = null   # whole bucket; or "incoming/" to scope
  replicate_delete_markers = true
}
```

- `create_source_bucket = false` attaches replication to a pre-existing (already
  versioned) source bucket instead of creating one. `create_destination_bucket = false`
  does the same for the replica.
- When `replication_prefix` is set, `base/s3-bucket` scopes the role's object
  permissions to that prefix.
- **Encryption:** `AES256` (default) needs nothing extra. For `aws:kms`, pass existing
  `source_kms_key_arn` / `destination_kms_key_arn` — this module does **not** create KMS
  keys (that would be logic, not glue).
- **Backfill:** live replication only copies objects written *after* it's enabled.
  Existing objects need a one-time S3 Batch Replication job (role must also trust
  `batchoperations.s3.amazonaws.com` + `s3:InitiateReplication`).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_destination"></a> [destination](#module\_destination) | ../../base/s3-bucket | n/a |
| <a name="module_source"></a> [source](#module\_source) | ../../base/s3-bucket | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_destination_bucket"></a> [create\_destination\_bucket](#input\_create\_destination\_bucket) | Create the destination (replica) bucket. Set false to replicate into an existing bucket referenced by destination\_bucket\_name (must already be versioned). | `bool` | `true` | no |
| <a name="input_create_source_bucket"></a> [create\_source\_bucket](#input\_create\_source\_bucket) | Create the source bucket. Set false to attach replication to an EXISTING source bucket (which must already be versioned). | `bool` | `true` | no |
| <a name="input_destination_bucket_name"></a> [destination\_bucket\_name](#input\_destination\_bucket\_name) | Name of the destination (replica) bucket in the aws.replica region. | `string` | n/a | yes |
| <a name="input_destination_kms_key_arn"></a> [destination\_kms\_key\_arn](#input\_destination\_kms\_key\_arn) | Existing KMS key ARN (replica region) for the destination bucket + replica encryption when sse\_algorithm is aws:kms. | `string` | `null` | no |
| <a name="input_destination_storage_class"></a> [destination\_storage\_class](#input\_destination\_storage\_class) | Storage class for replicated objects in the destination bucket. | `string` | `"STANDARD"` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow deletion of non-empty buckets this module creates. | `bool` | `false` | no |
| <a name="input_replicate_delete_markers"></a> [replicate\_delete\_markers](#input\_replicate\_delete\_markers) | Replicate delete markers from source to destination. | `bool` | `false` | no |
| <a name="input_replication_prefix"></a> [replication\_prefix](#input\_replication\_prefix) | Optional key prefix to scope replication to. Null replicates the whole bucket. | `string` | `null` | no |
| <a name="input_replication_role_name"></a> [replication\_role\_name](#input\_replication\_role\_name) | Name of the IAM role S3 uses for replication. Defaults to a name derived from the source bucket. | `string` | `null` | no |
| <a name="input_replication_rule_id"></a> [replication\_rule\_id](#input\_replication\_rule\_id) | Identifier for the replication rule. | `string` | `"crr"` | no |
| <a name="input_source_bucket_name"></a> [source\_bucket\_name](#input\_source\_bucket\_name) | Name of the source bucket (in the default provider's region). | `string` | n/a | yes |
| <a name="input_source_kms_key_arn"></a> [source\_kms\_key\_arn](#input\_source\_kms\_key\_arn) | Existing KMS key ARN (source region) for the source bucket when sse\_algorithm is aws:kms. Key creation is out of scope for this glue module. | `string` | `null` | no |
| <a name="input_sse_algorithm"></a> [sse\_algorithm](#input\_sse\_algorithm) | Server-side encryption algorithm for both buckets (AES256 or aws:kms). | `string` | `"AES256"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the buckets and the replication role. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_destination_bucket_arn"></a> [destination\_bucket\_arn](#output\_destination\_bucket\_arn) | The ARN of the destination (replica) bucket. |
| <a name="output_destination_bucket_id"></a> [destination\_bucket\_id](#output\_destination\_bucket\_id) | The ID (name) of the destination (replica) bucket. |
| <a name="output_replication_role_arn"></a> [replication\_role\_arn](#output\_replication\_role\_arn) | ARN of the IAM role S3 assumes for replication. |
| <a name="output_source_bucket_arn"></a> [source\_bucket\_arn](#output\_source\_bucket\_arn) | The ARN of the source bucket. |
| <a name="output_source_bucket_id"></a> [source\_bucket\_id](#output\_source\_bucket\_id) | The ID (name) of the source bucket. |
<!-- END_TF_DOCS -->