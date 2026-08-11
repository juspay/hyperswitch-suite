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
| <a name="module_firewall_rules"></a> [firewall\_rules](#module\_firewall\_rules) | ../../composition/firewall-rules | n/a |
| <a name="module_memorystore"></a> [memorystore](#module\_memorystore) | ../../composition/memorystore | n/a |
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | ../gke-workload-identity | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_project_roles"></a> [additional\_project\_roles](#input\_additional\_project\_roles) | Additional project-level IAM roles to grant the ratelimiter's service account | `list(string)` | `[]` | no |
| <a name="input_authorized_network"></a> [authorized\_network](#input\_authorized\_network) | Self-link/ID of the VPC network to peer the Memorystore instance to (requires Private Service Access) | `string` | `null` | no |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster hosting the ratelimiter | `string` | n/a | yes |
| <a name="input_create_firewall_rule"></a> [create\_firewall\_rule](#input\_create\_firewall\_rule) | Whether to create the firewall rule allowing GKE pods to reach the Memorystore instance | `bool` | `true` | no |
| <a name="input_create_redis"></a> [create\_redis](#input\_create\_redis) | Whether to create a dedicated Memorystore instance for the ratelimiter | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_gke_pods_cidr"></a> [gke\_pods\_cidr](#input\_gke\_pods\_cidr) | CIDR range of GKE pod IPs allowed to reach the Memorystore instance | `string` | `null` | no |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace the ratelimiter runs in | `string` | `"hyperswitch"` | no |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Kubernetes service account name used by the ratelimiter | `string` | `"ratelimiter"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Name of the VPC network, required when create\_firewall\_rule = true | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |
| <a name="input_redis_memory_size_gb"></a> [redis\_memory\_size\_gb](#input\_redis\_memory\_size\_gb) | Memorystore memory size in GB | `number` | `1` | no |
| <a name="input_redis_tier"></a> [redis\_tier](#input\_redis\_tier) | Memorystore service tier | `string` | `"STANDARD_HA"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the dedicated Memorystore instance | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Bound Kubernetes service account name |
| <a name="output_redis_host"></a> [redis\_host](#output\_redis\_host) | Host/IP of the dedicated Memorystore instance, if created |
| <a name="output_redis_port"></a> [redis\_port](#output\_redis\_port) | Port of the dedicated Memorystore instance, if created |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the ratelimiter's Google service account |
<!-- END_TF_DOCS -->
