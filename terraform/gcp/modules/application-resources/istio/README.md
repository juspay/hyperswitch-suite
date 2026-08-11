<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.1 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_firewall_rules"></a> [firewall\_rules](#module\_firewall\_rules) | ../../composition/firewall-rules | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_address.gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [helm_release.istio_base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_gateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#input\_cluster\_ca\_certificate) | Base64 encoded certificate data required to communicate with the cluster | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | Endpoint (host, without scheme) for the Kubernetes API server | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster | `string` | n/a | yes |
| <a name="input_create_firewall_rules"></a> [create\_firewall\_rules](#input\_create\_firewall\_rules) | Whether to create the firewall rule allowing ingress traffic to the gateway | `bool` | `true` | no |
| <a name="input_create_gateway_static_ip"></a> [create\_gateway\_static\_ip](#input\_create\_gateway\_static\_ip) | Whether to reserve a static regional IP for the gateway's LoadBalancer service | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_gateway_service_annotations"></a> [gateway\_service\_annotations](#input\_gateway\_service\_annotations) | Additional annotations applied to the gateway's LoadBalancer service | `map(string)` | `{}` | no |
| <a name="input_host_domains"></a> [host\_domains](#input\_host\_domains) | Map of logical name to hostname(s) served through this gateway, passed through as an output for wiring into DNS/routing config | `map(list(string))` | `{}` | no |
| <a name="input_istio_base"></a> [istio\_base](#input\_istio\_base) | Configuration for the Istio base chart | <pre>object({<br/>    enabled       = bool<br/>    release_name  = optional(string)<br/>    chart_repo    = optional(string)<br/>    chart_version = optional(string)<br/>    values        = optional(list(string), [])<br/>    values_file   = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_istio_gateway"></a> [istio\_gateway](#input\_istio\_gateway) | Configuration for the Istio gateway chart | <pre>object({<br/>    enabled       = bool<br/>    release_name  = optional(string)<br/>    chart_repo    = optional(string)<br/>    chart_version = optional(string)<br/>    values        = optional(list(string), [])<br/>    values_file   = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_istio_namespace"></a> [istio\_namespace](#input\_istio\_namespace) | Namespace to install Istio components into | `string` | `"istio-system"` | no |
| <a name="input_istiod"></a> [istiod](#input\_istiod) | Configuration for the istiod chart | <pre>object({<br/>    enabled       = bool<br/>    release_name  = optional(string)<br/>    chart_repo    = optional(string)<br/>    chart_version = optional(string)<br/>    values        = optional(list(string), [])<br/>    values_file   = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to created resources that support them | `map(string)` | `{}` | no |
| <a name="input_network"></a> [network](#input\_network) | Self-link of the VPC network | `string` | n/a | yes |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Name of the VPC network, required when create\_firewall\_rules = true | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the gateway's static IP | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the GKE cluster Istio is installed on |
| <a name="output_gateway_static_ip"></a> [gateway\_static\_ip](#output\_gateway\_static\_ip) | Static IP address reserved for the Istio gateway, if enabled |
| <a name="output_host_domains_map"></a> [host\_domains\_map](#output\_host\_domains\_map) | Passthrough of var.host\_domains |
<!-- END_TF_DOCS -->
