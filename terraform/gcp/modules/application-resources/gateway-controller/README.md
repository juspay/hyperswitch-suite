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
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | ../gke-workload-identity | n/a |

## Resources

| Name | Type |
|------|------|
| [google_compute_ssl_policy.gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_project_roles"></a> [additional\_project\_roles](#input\_additional\_project\_roles) | Additional project-level IAM roles to grant the controller-adjacent service account | `list(string)` | `[]` | no |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster. Required when create\_service\_account = true | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster. Required when create\_service\_account = true | `string` | `null` | no |
| <a name="input_create_service_account"></a> [create\_service\_account](#input\_create\_service\_account) | Whether to create a Workload Identity-bound service account for BackendConfig/FrontendConfig automation | `bool` | `false` | no |
| <a name="input_create_ssl_policy"></a> [create\_ssl\_policy](#input\_create\_ssl\_policy) | Whether to create an SSL policy governing minimum TLS version/cipher suite for GKE-managed load balancers | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace for the controller-adjacent service account | `string` | `"kube-system"` | no |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Kubernetes service account name for the controller-adjacent service account | `string` | `"gateway-controller"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to created resources that support them | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |
| <a name="input_ssl_policy_min_tls_version"></a> [ssl\_policy\_min\_tls\_version](#input\_ssl\_policy\_min\_tls\_version) | Minimum TLS version: TLS\_1\_0, TLS\_1\_1, or TLS\_1\_2 | `string` | `"TLS_1_2"` | no |
| <a name="input_ssl_policy_profile"></a> [ssl\_policy\_profile](#input\_ssl\_policy\_profile) | SSL policy profile: COMPATIBLE, MODERN, RESTRICTED, or CUSTOM | `string` | `"MODERN"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the controller-adjacent service account, if created |
| <a name="output_ssl_policy_id"></a> [ssl\_policy\_id](#output\_ssl\_policy\_id) | ID of the SSL policy, if created |
<!-- END_TF_DOCS -->
