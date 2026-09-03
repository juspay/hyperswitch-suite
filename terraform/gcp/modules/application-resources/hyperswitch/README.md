<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 7.46.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_dashboard_themes_bucket"></a> [dashboard\_themes\_bucket](#module\_dashboard\_themes\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |
| <a name="module_file_uploads_bucket"></a> [file\_uploads\_bucket](#module\_file\_uploads\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-google-modules/kms/google | 4.1.2 |
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | terraform-google-modules/kubernetes-engine/google//modules/workload-identity | 44.3.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_cloudfunctions2_function_iam_member.invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function_iam_member) | resource |
| [google_kms_crypto_key_iam_member.hyperswitch](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_project_iam_member.additional_custom_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_secret_manager_secret_iam_member.secrets](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_iam_member.smtp](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_service_account_iam_member.cross_project_impersonation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket_iam_member.existing_dashboard_themes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_iam_member.existing_file_uploads](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_custom_role_ids"></a> [additional\_custom\_role\_ids](#input\_additional\_custom\_role\_ids) | List of project-level custom role IDs (e.g. from application-resources/shared-iam-roles) to grant the service account | `list(string)` | `[]` | no |
| <a name="input_additional_project_roles"></a> [additional\_project\_roles](#input\_additional\_project\_roles) | Additional project-level IAM roles to grant Hyperswitch's service account | `list(string)` | `[]` | no |
| <a name="input_cloud_functions"></a> [cloud\_functions](#input\_cloud\_functions) | Cloud Functions configuration. Set enabled=true and list function\_names to grant invoker access | <pre>object({<br/>    enabled        = optional(bool, false)<br/>    location       = optional(string)<br/>    function_names = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#input\_cluster\_ca\_certificate) | GKE cluster CA certificate, base64-encoded - required to configure this module's kubernetes provider | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | GKE cluster API server endpoint (bare host:port or IP, no scheme) - required to configure this module's kubernetes provider | `string` | n/a | yes |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster hosting Hyperswitch | `string` | n/a | yes |
| <a name="input_cross_project_assume"></a> [cross\_project\_assume](#input\_cross\_project\_assume) | Cross-project impersonation configuration. Set enabled=true and list target\_service\_accounts to grant roles/iam.serviceAccountTokenCreator on them | <pre>object({<br/>    enabled                 = optional(bool, false)<br/>    target_service_accounts = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_gcs_dashboard_themes"></a> [gcs\_dashboard\_themes](#input\_gcs\_dashboard\_themes) | GCS bucket configuration for dashboard themes. Set create=true to create a new bucket, or create=false with bucket\_name set to an existing bucket to grant access to it | <pre>object({<br/>    create             = optional(bool, false)<br/>    bucket_name        = optional(string)<br/>    location           = optional(string, "US")<br/>    force_destroy      = optional(bool, false)<br/>    versioning_enabled = optional(bool, true)<br/>  })</pre> | `null` | no |
| <a name="input_gcs_file_uploads"></a> [gcs\_file\_uploads](#input\_gcs\_file\_uploads) | GCS bucket configuration for file uploads. Set create=true to create a new bucket, or create=false with bucket\_name set to an existing bucket to grant access to it | <pre>object({<br/>    create             = optional(bool, false)<br/>    bucket_name        = optional(string)<br/>    location           = optional(string, "US")<br/>    force_destroy      = optional(bool, false)<br/>    versioning_enabled = optional(bool, true)<br/>  })</pre> | `null` | no |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace Hyperswitch runs in | `string` | `"hyperswitch"` | no |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Kubernetes service account name used by Hyperswitch | `string` | `"hyperswitch"` | no |
| <a name="input_kms"></a> [kms](#input\_kms) | KMS configuration. Set create=true to create a keyring/key and grant the service account encrypt/decrypt access | <pre>object({<br/>    create          = optional(bool, false)<br/>    location        = optional(string)<br/>    keyring_name    = optional(string)<br/>    key_name        = optional(string)<br/>    rotation_period = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |
| <a name="input_public_domain"></a> [public\_domain](#input\_public\_domain) | Public domain name used to access Hyperswitch. Passed through as an output for wiring into DNS/certificate config | `string` | `null` | no |
| <a name="input_secret_ids"></a> [secret\_ids](#input\_secret\_ids) | List of Secret Manager secret IDs to grant the service account access to | `list(string)` | `[]` | no |
| <a name="input_smtp_secret_id"></a> [smtp\_secret\_id](#input\_smtp\_secret\_id) | Secret Manager secret ID holding SMTP credentials. Null disables granting access | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cross_project_assume_enabled"></a> [cross\_project\_assume\_enabled](#output\_cross\_project\_assume\_enabled) | Whether cross-project impersonation was granted |
| <a name="output_dashboard_themes_bucket_enabled"></a> [dashboard\_themes\_bucket\_enabled](#output\_dashboard\_themes\_bucket\_enabled) | Whether the dashboard-themes feature is enabled |
| <a name="output_dashboard_themes_bucket_name"></a> [dashboard\_themes\_bucket\_name](#output\_dashboard\_themes\_bucket\_name) | Name of the dashboard-themes bucket (created or existing), if enabled |
| <a name="output_file_uploads_bucket_enabled"></a> [file\_uploads\_bucket\_enabled](#output\_file\_uploads\_bucket\_enabled) | Whether the file-uploads feature is enabled |
| <a name="output_file_uploads_bucket_name"></a> [file\_uploads\_bucket\_name](#output\_file\_uploads\_bucket\_name) | Name of the file-uploads bucket (created or existing), if enabled |
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Bound Kubernetes service account name |
| <a name="output_kms_enabled"></a> [kms\_enabled](#output\_kms\_enabled) | Whether a KMS key was created for this application |
| <a name="output_kms_key_name"></a> [kms\_key\_name](#output\_kms\_key\_name) | Self-link of the KMS key, if created |
| <a name="output_lambda_enabled"></a> [lambda\_enabled](#output\_lambda\_enabled) | Whether Cloud Functions invoker access was granted |
| <a name="output_public_domain"></a> [public\_domain](#output\_public\_domain) | Passthrough of var.public\_domain |
| <a name="output_secrets_manager_enabled"></a> [secrets\_manager\_enabled](#output\_secrets\_manager\_enabled) | Whether Secrets Manager access was granted |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of Hyperswitch's Google service account |
| <a name="output_smtp_enabled"></a> [smtp\_enabled](#output\_smtp\_enabled) | Whether SMTP secret access was granted |
<!-- END_TF_DOCS -->
