<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_state_bucket"></a> [state\_bucket](#module\_state\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allow_destroy"></a> [allow\_destroy](#input\_allow\_destroy) | Allow destruction of the bucket even if it contains objects (should be false for prod) | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Self link of the KMS CryptoKey used to encrypt the bucket (null uses Google-managed encryption) | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | List of lifecycle rules for the state bucket | <pre>list(object({<br/>    action = object({<br/>      type          = string<br/>      storage_class = optional(string)<br/>    })<br/>    condition = object({<br/>      age                   = optional(number)<br/>      created_before        = optional(string)<br/>      with_state            = optional(string)<br/>      num_newer_versions    = optional(number)<br/>      matches_storage_class = optional(string)<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | GCS bucket location (region or multi-region, e.g. europe-west1 or EU) | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the state bucket is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for labeling and naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_retention_period_seconds"></a> [retention\_period\_seconds](#input\_retention\_period\_seconds) | Minimum retention period (seconds) objects must be retained. Null disables the retention policy | `number` | `null` | no |
| <a name="input_retention_policy_locked"></a> [retention\_policy\_locked](#input\_retention\_policy\_locked) | Whether the retention policy is locked (irreversible). Only used when retention\_period\_seconds is set | `bool` | `false` | no |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Name of the GCS bucket for Terraform state (must be globally unique) | `string` | n/a | yes |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class for the state bucket | `string` | `"STANDARD"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backend_config"></a> [backend\_config](#output\_backend\_config) | Backend configuration object for use in other Terraform deployments |
| <a name="output_backend_config_formatted"></a> [backend\_config\_formatted](#output\_backend\_config\_formatted) | Formatted backend configuration for copy-paste into backend.tf files |
| <a name="output_state_bucket_location"></a> [state\_bucket\_location](#output\_state\_bucket\_location) | The location of the state bucket |
| <a name="output_state_bucket_name"></a> [state\_bucket\_name](#output\_state\_bucket\_name) | The name of the state bucket |
| <a name="output_state_bucket_url"></a> [state\_bucket\_url](#output\_state\_bucket\_url) | The gsutil URI of the state bucket (gs://<name>) |
<!-- END_TF_DOCS -->
