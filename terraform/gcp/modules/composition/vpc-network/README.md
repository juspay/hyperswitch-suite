<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cloud_nat"></a> [cloud\_nat](#module\_cloud\_nat) | terraform-google-modules/cloud-nat/google | 7.0.0 |
| <a name="module_cloud_router"></a> [cloud\_router](#module\_cloud\_router) | terraform-google-modules/cloud-router/google | 9.0.0 |
| <a name="module_private_service_access"></a> [private\_service\_access](#module\_private\_service\_access) | terraform-google-modules/network/google//modules/private-service-access | 18.1.2 |
| <a name="module_vpc_network"></a> [vpc\_network](#module\_vpc\_network) | terraform-google-modules/network/google | 18.1.2 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_custom_subnets"></a> [custom\_subnets](#input\_custom\_subnets) | Additional custom subnets keyed by tier name, merged alongside the named tiers | <pre>map(object({<br/>    cidr                     = string<br/>    private_ip_google_access = optional(bool, true)<br/>    purpose                  = optional(string)<br/>    description              = optional(string)<br/>    secondary_ranges = optional(list(object({<br/>      range_name    = string<br/>      ip_cidr_range = string<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_data_stack_subnet_cidr"></a> [data\_stack\_subnet\_cidr](#input\_data\_stack\_subnet\_cidr) | CIDR for the Kafka/Cassandra/ClickHouse/OpenSearch data-stack subnet | `string` | `null` | no |
| <a name="input_database_subnet_cidr"></a> [database\_subnet\_cidr](#input\_database\_subnet\_cidr) | CIDR for the database-adjacent subnet (Cloud SQL proxies, private consumers) | `string` | `null` | no |
| <a name="input_enable_default_deny_ingress"></a> [enable\_default\_deny\_ingress](#input\_enable\_default\_deny\_ingress) | Whether to add a lowest-priority default-deny-all ingress rule | `bool` | `true` | no |
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | Enable VPC flow logs on every created subnet | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_external_incoming_subnet_cidr"></a> [external\_incoming\_subnet\_cidr](#input\_external\_incoming\_subnet\_cidr) | CIDR for the internet-facing (external load balancer) subnet | `string` | n/a | yes |
| <a name="input_gke_nodes_subnet_cidr"></a> [gke\_nodes\_subnet\_cidr](#input\_gke\_nodes\_subnet\_cidr) | Primary CIDR for the GKE node pool subnet | `string` | n/a | yes |
| <a name="input_gke_pods_secondary_range_cidr"></a> [gke\_pods\_secondary\_range\_cidr](#input\_gke\_pods\_secondary\_range\_cidr) | Secondary range CIDR for GKE pod alias IPs | `string` | n/a | yes |
| <a name="input_gke_services_secondary_range_cidr"></a> [gke\_services\_secondary\_range\_cidr](#input\_gke\_services\_secondary\_range\_cidr) | Secondary range CIDR for GKE service alias IPs | `string` | n/a | yes |
| <a name="input_incoming_envoy_subnet_cidr"></a> [incoming\_envoy\_subnet\_cidr](#input\_incoming\_envoy\_subnet\_cidr) | CIDR for the Envoy ingress proxy subnet | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_locker_database_subnet_cidr"></a> [locker\_database\_subnet\_cidr](#input\_locker\_database\_subnet\_cidr) | CIDR for the PCI-DSS scoped locker database subnet | `string` | `null` | no |
| <a name="input_locker_server_subnet_cidr"></a> [locker\_server\_subnet\_cidr](#input\_locker\_server\_subnet\_cidr) | CIDR for the PCI-DSS scoped locker server subnet | `string` | `null` | no |
| <a name="input_management_subnet_cidr"></a> [management\_subnet\_cidr](#input\_management\_subnet\_cidr) | CIDR for the bastion/jump-host subnet | `string` | n/a | yes |
| <a name="input_memorystore_subnet_cidr"></a> [memorystore\_subnet\_cidr](#input\_memorystore\_subnet\_cidr) | Reserved CIDR range for Memorystore direct-peering instances | `string` | `null` | no |
| <a name="input_mtu"></a> [mtu](#input\_mtu) | Maximum transmission unit for the VPC | `number` | `1460` | no |
| <a name="input_nat_min_ports_per_vm"></a> [nat\_min\_ports\_per\_vm](#input\_nat\_min\_ports\_per\_vm) | Minimum number of ports allocated per VM for Cloud NAT | `number` | `64` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Name of the VPC network | `string` | n/a | yes |
| <a name="input_outgoing_proxy_subnet_cidr"></a> [outgoing\_proxy\_subnet\_cidr](#input\_outgoing\_proxy\_subnet\_cidr) | CIDR for the Squid egress proxy subnet | `string` | `null` | no |
| <a name="input_private_service_access_prefix_length"></a> [private\_service\_access\_prefix\_length](#input\_private\_service\_access\_prefix\_length) | Prefix length of the reserved IP range for Private Service Access peering | `number` | `16` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the network is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region all subnets and regional resources (router, NAT, PSA) are created in | `string` | n/a | yes |
| <a name="input_router_asn"></a> [router\_asn](#input\_router\_asn) | BGP ASN for the Cloud Router | `number` | `64514` | no |
| <a name="input_routing_mode"></a> [routing\_mode](#input\_routing\_mode) | Network routing mode: GLOBAL or REGIONAL | `string` | `"GLOBAL"` | no |
| <a name="input_serverless_connector_subnet_cidr"></a> [serverless\_connector\_subnet\_cidr](#input\_serverless\_connector\_subnet\_cidr) | CIDR (/28) for the Serverless VPC Access connector used by Cloud Functions/Cloud Run | `string` | `null` | no |
| <a name="input_utils_subnet_cidr"></a> [utils\_subnet\_cidr](#input\_utils\_subnet\_cidr) | CIDR for shared utility workloads | `string` | `null` | no |
| <a name="input_vpc_internal_ranges"></a> [vpc\_internal\_ranges](#input\_vpc\_internal\_ranges) | Map of CIDR ranges considered internal to the VPC, allowed to talk to each other on the allow-internal rule | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_gke_nodes_subnet_self_link"></a> [gke\_nodes\_subnet\_self\_link](#output\_gke\_nodes\_subnet\_self\_link) | Self-link of the GKE node pool subnet |
| <a name="output_gke_pods_secondary_range_name"></a> [gke\_pods\_secondary\_range\_name](#output\_gke\_pods\_secondary\_range\_name) | Name of the GKE pods secondary range, for wiring into composition/gke |
| <a name="output_gke_services_secondary_range_name"></a> [gke\_services\_secondary\_range\_name](#output\_gke\_services\_secondary\_range\_name) | Name of the GKE services secondary range, for wiring into composition/gke |
| <a name="output_nat_name"></a> [nat\_name](#output\_nat\_name) | Name of the Cloud NAT gateway |
| <a name="output_network_id"></a> [network\_id](#output\_network\_id) | The ID of the VPC network |
| <a name="output_network_name"></a> [network\_name](#output\_network\_name) | The name of the VPC network |
| <a name="output_network_self_link"></a> [network\_self\_link](#output\_network\_self\_link) | The self-link of the VPC network |
| <a name="output_private_service_access_enabled"></a> [private\_service\_access\_enabled](#output\_private\_service\_access\_enabled) | Whether the Private Service Access peering range/connection was created; downstream Cloud SQL/Memorystore modules should depend\_on this module before using it |
| <a name="output_router_name"></a> [router\_name](#output\_router\_name) | Name of the Cloud Router |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | Map of created subnets, keyed by region/name, as returned by the network module |
| <a name="output_subnets_by_tier"></a> [subnets\_by\_tier](#output\_subnets\_by\_tier) | Map of subnet self-links keyed by tier name (external-incoming, management, gke-nodes, ...) |
<!-- END_TF_DOCS -->
