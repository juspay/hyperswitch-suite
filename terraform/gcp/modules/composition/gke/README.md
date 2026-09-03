<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_gke"></a> [gke](#module\_gke) | terraform-google-modules/kubernetes-engine/google//modules/private-cluster | 44.3.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_firewall.allow_egress_to_master](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster. Defaults to '<environment>-<project\_name>-gke', or '<environment>-<project\_name>-gke-<cluster\_name\_version>' if that's set. Setting this always wins outright over both. | `string` | `null` | no |
| <a name="input_cluster_name_version"></a> [cluster\_name\_version](#input\_cluster\_name\_version) | Optional identifier appended to the computed cluster name ("<environment>-<project\_name>-gke-<cluster\_name\_version>"), for running more than one cluster in the same environment. Null (default) appends nothing. The cluster name is ForceNew, so setting or changing this on a live cluster replaces it | `string` | `null` | no |
| <a name="input_create_master_egress_firewall_rule"></a> [create\_master\_egress\_firewall\_rule](#input\_create\_master\_egress\_firewall\_rule) | Whether to create the EGRESS firewall rule letting nodes reach the private control-plane endpoint. GKE auto-creates only the ingress side, so this is required for a private cluster. Skipped regardless when master\_ipv4\_cidr\_block is null, or when node\_pools\_tags is empty (a rule with no target\_tags would apply network-wide) | `bool` | `true` | no |
| <a name="input_create_service_account"></a> [create\_service\_account](#input\_create\_service\_account) | Whether to create a dedicated node service account | `bool` | `true` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Whether to allow Terraform to destroy the cluster | `bool` | `true` | no |
| <a name="input_enable_network_policy"></a> [enable\_network\_policy](#input\_enable\_network\_policy) | Enable the network policy addon (Calico) | `bool` | `false` | no |
| <a name="input_enable_node_auto_upgrade"></a> [enable\_node\_auto\_upgrade](#input\_enable\_node\_auto\_upgrade) | Whether GKE may automatically upgrade node pool versions on its own schedule. Defaults to false, since auto-upgrades replace running nodes without an explicit apply. Applies uniformly to every entry in var.node\_pools, overriding their own auto\_upgrade key. Does not gate the control plane's own release\_channel upgrade cadence | `bool` | `false` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | Whether the cluster's master is only accessible via its internal IP address | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_gateway_api_channel"></a> [gateway\_api\_channel](#input\_gateway\_api\_channel) | Gateway API channel: CHANNEL\_DISABLED, CHANNEL\_EXPERIMENTAL, or CHANNEL\_STANDARD | `string` | `"CHANNEL_STANDARD"` | no |
| <a name="input_ip_range_pods"></a> [ip\_range\_pods](#input\_ip\_range\_pods) | Name of the secondary subnet IP range to use for pod alias IPs | `string` | n/a | yes |
| <a name="input_ip_range_services"></a> [ip\_range\_services](#input\_ip\_range\_services) | Name of the secondary subnet IP range to use for service alias IPs | `string` | n/a | yes |
| <a name="input_kms_key_name"></a> [kms\_key\_name](#input\_kms\_key\_name) | Cloud KMS CryptoKey self-link used for application-layer secrets (etcd) encryption. Null disables envelope encryption | `string` | `null` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version for the control plane. 'latest' pulls the latest available version in the region | `string` | `"latest"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels applied to the cluster | `map(string)` | `{}` | no |
| <a name="input_logging_service"></a> [logging\_service](#input\_logging\_service) | Logging service the cluster writes to | `string` | `"logging.googleapis.com/kubernetes"` | no |
| <a name="input_master_authorized_networks"></a> [master\_authorized\_networks](#input\_master\_authorized\_networks) | List of CIDR blocks allowed to access the Kubernetes master | <pre>list(object({<br/>    cidr_block   = string<br/>    display_name = string<br/>  }))</pre> | `[]` | no |
| <a name="input_master_ipv4_cidr_block"></a> [master\_ipv4\_cidr\_block](#input\_master\_ipv4\_cidr\_block) | /28 CIDR block for the control plane's private network | `string` | `null` | no |
| <a name="input_monitoring_service"></a> [monitoring\_service](#input\_monitoring\_service) | Monitoring service the cluster writes to | `string` | `"monitoring.googleapis.com/kubernetes"` | no |
| <a name="input_network"></a> [network](#input\_network) | Self-link of the VPC network to host the cluster in | `string` | n/a | yes |
| <a name="input_network_project_id"></a> [network\_project\_id](#input\_network\_project\_id) | Project ID of the Shared VPC host project, if applicable | `string` | `""` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | List of node pool configuration maps, mirroring the upstream module's node\_pools variable (name, machine\_type, min\_count, max\_count, disk\_size\_gb, spot, etc.) | `list(map(any))` | <pre>[<br/>  {<br/>    "auto_repair": true,<br/>    "auto_upgrade": true,<br/>    "disk_size_gb": 100,<br/>    "disk_type": "pd-balanced",<br/>    "machine_type": "e2-standard-4",<br/>    "max_count": 5,<br/>    "min_count": 1,<br/>    "name": "default-pool"<br/>  }<br/>]</pre> | no |
| <a name="input_node_pools_labels"></a> [node\_pools\_labels](#input\_node\_pools\_labels) | Map of node-pool name to Kubernetes labels applied to that pool's nodes | `map(map(string))` | `{}` | no |
| <a name="input_node_pools_metadata"></a> [node\_pools\_metadata](#input\_node\_pools\_metadata) | Map of node-pool name to a map of additional instance metadata | `map(map(string))` | `{}` | no |
| <a name="input_node_pools_oauth_scopes"></a> [node\_pools\_oauth\_scopes](#input\_node\_pools\_oauth\_scopes) | Map of node-pool name to a list of OAuth scopes granted to that pool's nodes | `map(list(string))` | <pre>{<br/>  "all": [<br/>    "https://www.googleapis.com/auth/cloud-platform"<br/>  ]<br/>}</pre> | no |
| <a name="input_node_pools_tags"></a> [node\_pools\_tags](#input\_node\_pools\_tags) | Map of node-pool name to a list of GCE network tags applied to that pool's nodes | `map(list(string))` | `{}` | no |
| <a name="input_node_pools_taints"></a> [node\_pools\_taints](#input\_node\_pools\_taints) | Map of node-pool name to a list of Kubernetes taints applied to that pool's nodes | <pre>map(list(object({<br/>    key    = string<br/>    value  = string<br/>    effect = string<br/>  })))</pre> | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the cluster is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to host the cluster in (required for regional clusters) | `string` | n/a | yes |
| <a name="input_regional"></a> [regional](#input\_regional) | Whether the cluster is regional (multi-zone control plane) or zonal | `bool` | `true` | no |
| <a name="input_release_channel"></a> [release\_channel](#input\_release\_channel) | Release channel: UNSPECIFIED, RAPID, REGULAR, or STABLE | `string` | `"REGULAR"` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Existing service account email to run nodes as. Ignored if create\_service\_account is true | `string` | `""` | no |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | Self-link of the subnetwork to host the cluster nodes in | `string` | n/a | yes |
| <a name="input_zones"></a> [zones](#input\_zones) | Zones to host the cluster/nodes in (required for zonal clusters, optional otherwise) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ca_certificate"></a> [ca\_certificate](#output\_ca\_certificate) | Base64-encoded cluster CA certificate |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of the GKE cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the GKE cluster |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Cluster master endpoint (internal or external depending on enable\_private\_endpoint) |
| <a name="output_location"></a> [location](#output\_location) | Cluster location (region for regional clusters, zone for zonal) |
| <a name="output_master_egress_firewall_rule_name"></a> [master\_egress\_firewall\_rule\_name](#output\_master\_egress\_firewall\_rule\_name) | Name of the node->control-plane egress firewall rule this module creates (null if create\_master\_egress\_firewall\_rule is false, master\_ipv4\_cidr\_block is unset, or node\_pools\_tags is empty) |
| <a name="output_master_version"></a> [master\_version](#output\_master\_version) | Current master Kubernetes version |
| <a name="output_node_pools_names"></a> [node\_pools\_names](#output\_node\_pools\_names) | Names of the created node pools |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | Email of the service account used by cluster nodes |
| <a name="output_workload_identity_pool"></a> [workload\_identity\_pool](#output\_workload\_identity\_pool) | Workload Identity pool, in the form <project\_id>.svc.id.goog |
<!-- END_TF_DOCS -->
