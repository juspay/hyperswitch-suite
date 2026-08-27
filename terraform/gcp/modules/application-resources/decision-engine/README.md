<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bucket"></a> [bucket](#module\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | ../gke-workload-identity | n/a |

## Resources

| Name | Type |
|------|------|
| [google_secret_manager_secret_iam_member.smtp_credentials](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_project_roles"></a> [additional\_project\_roles](#input\_additional\_project\_roles) | Additional project-level IAM roles to grant decision-engine's service account | `list(string)` | `[]` | no |
| <a name="input_bucket_force_destroy"></a> [bucket\_force\_destroy](#input\_bucket\_force\_destroy) | Whether to allow bucket deletion with objects in it | `bool` | `false` | no |
| <a name="input_bucket_location"></a> [bucket\_location](#input\_bucket\_location) | Location for the dedicated bucket | `string` | `"US"` | no |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster hosting decision-engine | `string` | n/a | yes |
| <a name="input_create_bucket"></a> [create\_bucket](#input\_create\_bucket) | Whether to create a dedicated GCS bucket for decision-engine | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace decision-engine runs in | `string` | `"hyperswitch"` | no |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Kubernetes service account name used by decision-engine | `string` | `"decision-engine"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Custom bucket name. If null, auto-generated as '<env>-<project>-decision-engine-storage' | `string` | `null` | no |
| <a name="input_smtp_secret_id"></a> [smtp\_secret\_id](#input\_smtp\_secret\_id) | Secret Manager secret ID holding SMTP credentials (replaces AWS SES). Null skips granting access | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the dedicated bucket, if created |
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Bound Kubernetes service account name |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of decision-engine's Google service account |
<!-- END_TF_DOCS -->
