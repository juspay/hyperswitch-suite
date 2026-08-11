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
| <a name="module_database"></a> [database](#module\_database) | ../../composition/cloud-sql | n/a |
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | ../gke-workload-identity | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_project_roles"></a> [additional\_project\_roles](#input\_additional\_project\_roles) | Additional project-level IAM roles to grant Superposition's service account | `list(string)` | `[]` | no |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster hosting Superposition | `string` | n/a | yes |
| <a name="input_create_database"></a> [create\_database](#input\_create\_database) | Whether to create a dedicated Cloud SQL database for Superposition | `bool` | `true` | no |
| <a name="input_database_config"></a> [database\_config](#input\_database\_config) | Configuration for Superposition's dedicated Cloud SQL database (composition/cloud-sql) | <pre>object({<br/>    network_id          = string<br/>    instance_name       = optional(string)<br/>    database_version    = optional(string)<br/>    tier                = optional(string)<br/>    availability_type   = optional(string)<br/>    disk_size           = optional(number)<br/>    deletion_protection = optional(bool)<br/>    database_name       = optional(string)<br/>    master_username     = optional(string)<br/>    master_password     = optional(string)<br/>    encryption_key_name = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace Superposition runs in | `string` | `"hyperswitch"` | no |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Kubernetes service account name used by Superposition | `string` | `"superposition"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the dedicated Cloud SQL database | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_instance_connection_name"></a> [database\_instance\_connection\_name](#output\_database\_instance\_connection\_name) | Cloud SQL Auth Proxy connection name for Superposition's database, if created |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Name of the Superposition database, if created |
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Bound Kubernetes service account name |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of Superposition's Google service account |
<!-- END_TF_DOCS -->
