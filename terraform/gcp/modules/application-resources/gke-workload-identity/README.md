<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bucket"></a> [bucket](#module\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | terraform-google-modules/kubernetes-engine/google//modules/workload-identity | 44.3.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_annotate_k8s_sa"></a> [annotate\_k8s\_sa](#input\_annotate\_k8s\_sa) | Whether to annotate the Kubernetes service account with the GCP service account email | `bool` | `true` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Application name (e.g. hyperswitch, control-centre) | `string` | n/a | yes |
| <a name="input_bucket_enable_versioning"></a> [bucket\_enable\_versioning](#input\_bucket\_enable\_versioning) | Enable versioning for the companion bucket | `bool` | `false` | no |
| <a name="input_bucket_force_destroy"></a> [bucket\_force\_destroy](#input\_bucket\_force\_destroy) | Whether to allow bucket deletion with objects in it | `bool` | `false` | no |
| <a name="input_bucket_location"></a> [bucket\_location](#input\_bucket\_location) | Location for the companion bucket | `string` | `"US"` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Custom bucket name. If null, auto-generated as '<project>-<env>-<app>-storage' | `string` | `null` | no |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster hosting the workload | `string` | n/a | yes |
| <a name="input_create_bucket"></a> [create\_bucket](#input\_create\_bucket) | Whether to create a companion GCS bucket alongside the service account | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g. sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace of the service account to bind | `string` | n/a | yes |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Name of the Kubernetes service account to bind via Workload Identity | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to created resources that support them | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | n/a | yes |
| <a name="input_project_roles"></a> [project\_roles](#input\_project\_roles) | List of project-level IAM roles to grant the Google service account (e.g. ['roles/logging.logWriter']) | `list(string)` | `[]` | no |
| <a name="input_service_account_id"></a> [service\_account\_id](#input\_service\_account\_id) | Custom Google service account ID. If null, auto-generated as '<project>-<env>-<app>-sa' | `string` | `null` | no |
| <a name="input_use_existing_k8s_sa"></a> [use\_existing\_k8s\_sa](#input\_use\_existing\_k8s\_sa) | Whether the Kubernetes service account already exists (skip creating it) | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the companion bucket, if created |
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Name of the bound Kubernetes service account |
| <a name="output_k8s_service_account_namespace"></a> [k8s\_service\_account\_namespace](#output\_k8s\_service\_account\_namespace) | Namespace of the bound Kubernetes service account |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the created Google service account |
| <a name="output_service_account_name"></a> [service\_account\_name](#output\_service\_account\_name) | Fully qualified name of the Google service account |
<!-- END_TF_DOCS -->
