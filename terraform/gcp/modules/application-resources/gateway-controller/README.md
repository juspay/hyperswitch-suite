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
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | terraform-google-modules/kubernetes-engine/google//modules/workload-identity | 44.3.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_ssl_policy.gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_policy) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_project_roles"></a> [additional\_project\_roles](#input\_additional\_project\_roles) | Project-level IAM roles to grant the controller-adjacent service account | `list(string)` | `[]` | no |
| <a name="input_annotate_k8s_sa"></a> [annotate\_k8s\_sa](#input\_annotate\_k8s\_sa) | Whether to annotate the Kubernetes service account with the Google service account email | `bool` | `true` | no |
| <a name="input_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#input\_cluster\_ca\_certificate) | GKE cluster CA certificate, base64-encoded. Required when create\_service\_account = true - configures this module's kubernetes provider | `string` | `null` | no |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | GKE cluster API server endpoint (bare host:port or IP, no scheme). Required when create\_service\_account = true - configures this module's kubernetes provider | `string` | `null` | no |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster. Required when create\_service\_account = true | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster. Required when create\_service\_account = true | `string` | `null` | no |
| <a name="input_create_service_account"></a> [create\_service\_account](#input\_create\_service\_account) | Whether to create a Workload Identity-bound service account for BackendConfig/FrontendConfig automation. The GKE Ingress/Gateway controllers themselves do NOT need this | `bool` | `false` | no |
| <a name="input_create_ssl_policy"></a> [create\_ssl\_policy](#input\_create\_ssl\_policy) | Whether to create an SSL policy governing the minimum TLS version and cipher profile for the load balancers GKE creates. Attach it from a FrontendConfig's spec.sslPolicy using the ssl\_policy\_name output | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace for the controller-adjacent service account | `string` | `"kube-system"` | no |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Kubernetes service account name for the controller-adjacent service account | `string` | `"gateway-controller"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to created resources that support them | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |
| <a name="input_ssl_policy_custom_features"></a> [ssl\_policy\_custom\_features](#input\_ssl\_policy\_custom\_features) | Explicit cipher suite list. Only read when ssl\_policy\_profile = CUSTOM; ignored (and not sent to the API) otherwise | `list(string)` | `[]` | no |
| <a name="input_ssl_policy_min_tls_version"></a> [ssl\_policy\_min\_tls\_version](#input\_ssl\_policy\_min\_tls\_version) | Minimum TLS version: TLS\_1\_0, TLS\_1\_1, or TLS\_1\_2 | `string` | `"TLS_1_2"` | no |
| <a name="input_ssl_policy_profile"></a> [ssl\_policy\_profile](#input\_ssl\_policy\_profile) | SSL policy profile: COMPATIBLE, MODERN, RESTRICTED, or CUSTOM. CUSTOM requires ssl\_policy\_custom\_features | `string` | `"MODERN"` | no |
| <a name="input_use_existing_k8s_sa"></a> [use\_existing\_k8s\_sa](#input\_use\_existing\_k8s\_sa) | Whether the Kubernetes service account already exists (skip creating it and bind Workload Identity to it instead) | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Bound Kubernetes service account name, if created |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the controller-adjacent service account, if created |
| <a name="output_ssl_policy_id"></a> [ssl\_policy\_id](#output\_ssl\_policy\_id) | ID of the SSL policy, if created |
| <a name="output_ssl_policy_name"></a> [ssl\_policy\_name](#output\_ssl\_policy\_name) | Name of the SSL policy - this is the value to put in a GKE FrontendConfig's spec.sslPolicy to actually attach it to a load balancer |
| <a name="output_ssl_policy_self_link"></a> [ssl\_policy\_self\_link](#output\_ssl\_policy\_self\_link) | Self-link of the SSL policy, for callers attaching it to a target proxy directly rather than through a FrontendConfig |
<!-- END_TF_DOCS -->
