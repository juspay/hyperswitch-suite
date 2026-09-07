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
| <a name="module_database"></a> [database](#module\_database) | ../../composition/alloydb | n/a |
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | terraform-google-modules/kubernetes-engine/google//modules/workload-identity | 44.3.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_project_roles"></a> [additional\_project\_roles](#input\_additional\_project\_roles) | Additional project-level IAM roles to grant Superposition's service account | `list(string)` | `[]` | no |
| <a name="input_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#input\_cluster\_ca\_certificate) | GKE cluster CA certificate, base64-encoded - required to configure this module's kubernetes provider | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | GKE cluster API server endpoint (bare host:port or IP, no scheme) - required to configure this module's kubernetes provider | `string` | n/a | yes |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster hosting Superposition | `string` | n/a | yes |
| <a name="input_create_database"></a> [create\_database](#input\_create\_database) | Whether to create a dedicated AlloyDB cluster for Superposition | `bool` | `true` | no |
| <a name="input_database_config"></a> [database\_config](#input\_database\_config) | Configuration for Superposition's dedicated AlloyDB cluster (composition/alloydb).<br/><br/>allocated\_ip\_range is REQUIRED whenever create\_database is true - AlloyDB<br/>attaches over Private Service Access and composition/alloydb takes the<br/>reserved range by name, not by CIDR (composition/vpc-network exposes it as<br/>private\_service\_access\_range\_name). It is typed optional purely so callers<br/>that set create\_database = false need not supply it: Terraform validates<br/>full object conformance regardless of the count-gated branch that reads it.<br/><br/>There is deliberately no database\_name attribute, unlike the Cloud SQL<br/>shape this replaced. The google provider ships no resource for an<br/>individual AlloyDB database (only alloydb\_cluster / \_instance / \_user /<br/>\_backup), so the cluster's bootstrap `postgres` database is what exists<br/>after apply and any additional logical database is a SQL-level concern.<br/><br/>Cloud SQL's tier and disk\_size have no AlloyDB counterpart either - size<br/>the primary with cpu\_count (or machine\_type), and storage is managed by<br/>the service. | <pre>object({<br/>    network_id          = string<br/>    allocated_ip_range  = optional(string)<br/>    cluster_id          = optional(string)<br/>    database_version    = optional(string)<br/>    availability_type   = optional(string)<br/>    cpu_count           = optional(number)<br/>    machine_type        = optional(string)<br/>    database_flags      = optional(map(string))<br/>    deletion_protection = optional(bool)<br/>    master_username     = optional(string)<br/>    master_password     = optional(string)<br/>    encryption_key_name = optional(string)<br/>    secret_manager = optional(object({<br/>      create    = optional(bool, false)<br/>      secret_id = optional(string)<br/>    }))<br/>  })</pre> | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace Superposition runs in | `string` | `"hyperswitch"` | no |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Kubernetes service account name used by Superposition | `string` | `"superposition"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the dedicated Cloud SQL database | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_database_cluster_id"></a> [database\_cluster\_id](#output\_database\_cluster\_id) | ID of Superposition's AlloyDB cluster, if created |
| <a name="output_database_host"></a> [database\_host](#output\_database\_host) | Private IP of the AlloyDB primary instance - use as Superposition's database host, if created |
| <a name="output_database_master_username"></a> [database\_master\_username](#output\_database\_master\_username) | Bootstrap admin username on Superposition's AlloyDB cluster, if created |
| <a name="output_database_password_secret_id"></a> [database\_password\_secret\_id](#output\_database\_password\_secret\_id) | Secret Manager secret ID holding the generated master password, if database\_config.secret\_manager.create was set |
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Bound Kubernetes service account name |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of Superposition's Google service account |
<!-- END_TF_DOCS -->
