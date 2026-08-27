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
| <a name="module_internal_lb"></a> [internal\_lb](#module\_internal\_lb) | terraform-google-modules/lb-internal/google | 7.1.0 |
| <a name="module_keeper_instances"></a> [keeper\_instances](#module\_keeper\_instances) | terraform-google-modules/vm/google//modules/compute_instance | 15.2.1 |
| <a name="module_keeper_template"></a> [keeper\_template](#module\_keeper\_template) | terraform-google-modules/vm/google//modules/instance_template | 15.2.1 |
| <a name="module_server_group"></a> [server\_group](#module\_server\_group) | terraform-google-modules/vm/google//modules/umig | 15.2.1 |
| <a name="module_server_template"></a> [server\_template](#module\_server\_template) | terraform-google-modules/vm/google//modules/instance_template | 15.2.1 |
| <a name="module_service_account"></a> [service\_account](#module\_service\_account) | terraform-google-modules/service-accounts/google | 4.7.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_address.keeper](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_attached_disk.keeper_data](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk) | resource |
| [google_compute_attached_disk.server_data](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk) | resource |
| [google_compute_disk.keeper_data](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_disk.server_data](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Persistent disk type used for both boot and data disks | `string` | `"pd-ssd"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_keeper_boot_disk_size_gb"></a> [keeper\_boot\_disk\_size\_gb](#input\_keeper\_boot\_disk\_size\_gb) | Boot disk size in GB for keeper instances | `number` | `50` | no |
| <a name="input_keeper_count"></a> [keeper\_count](#input\_keeper\_count) | Number of ClickHouse Keeper instances (should be odd for quorum) | `number` | `3` | no |
| <a name="input_keeper_disk_size_gb"></a> [keeper\_disk\_size\_gb](#input\_keeper\_disk\_size\_gb) | Attached data disk size in GB per keeper instance | `number` | `50` | no |
| <a name="input_keeper_image"></a> [keeper\_image](#input\_keeper\_image) | Self-link or family of the custom image with ClickHouse Keeper pre-installed | `string` | n/a | yes |
| <a name="input_keeper_machine_type"></a> [keeper\_machine\_type](#input\_keeper\_machine\_type) | Machine type for keeper instances | `string` | `"n2-standard-2"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_lb_subnetwork"></a> [lb\_subnetwork](#input\_lb\_subnetwork) | Self-link of the subnetwork for the internal load balancer's forwarding rule | `string` | n/a | yes |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Additional instance metadata applied to both tiers (e.g. startup-script parameters) | `map(string)` | `{}` | no |
| <a name="input_network"></a> [network](#input\_network) | Self-link of the VPC network | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where instances are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for regional resources | `string` | n/a | yes |
| <a name="input_server_boot_disk_size_gb"></a> [server\_boot\_disk\_size\_gb](#input\_server\_boot\_disk\_size\_gb) | Boot disk size in GB for server instances | `number` | `50` | no |
| <a name="input_server_count"></a> [server\_count](#input\_server\_count) | Number of ClickHouse server instances | `number` | `2` | no |
| <a name="input_server_disk_size_gb"></a> [server\_disk\_size\_gb](#input\_server\_disk\_size\_gb) | Attached data disk size in GB per server instance | `number` | `1000` | no |
| <a name="input_server_http_port"></a> [server\_http\_port](#input\_server\_http\_port) | ClickHouse HTTP interface port | `number` | `8123` | no |
| <a name="input_server_image"></a> [server\_image](#input\_server\_image) | Self-link or family of the custom image with the ClickHouse server pre-installed | `string` | n/a | yes |
| <a name="input_server_machine_type"></a> [server\_machine\_type](#input\_server\_machine\_type) | Machine type for server instances | `string` | `"n2-standard-8"` | no |
| <a name="input_server_native_port"></a> [server\_native\_port](#input\_server\_native\_port) | ClickHouse native TCP protocol port | `number` | `9000` | no |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | Self-link of the subnetwork for ClickHouse nodes | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | Zone to create instances in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_internal_lb_ip_address"></a> [internal\_lb\_ip\_address](#output\_internal\_lb\_ip\_address) | IP address of the internal load balancer in front of the server tier |
| <a name="output_keeper_instance_self_links"></a> [keeper\_instance\_self\_links](#output\_keeper\_instance\_self\_links) | Self-links of the ClickHouse keeper instances |
| <a name="output_keeper_internal_ips"></a> [keeper\_internal\_ips](#output\_keeper\_internal\_ips) | Static internal IP addresses assigned to keeper instances |
| <a name="output_server_instance_self_links"></a> [server\_instance\_self\_links](#output\_server\_instance\_self\_links) | Self-links of the ClickHouse server instances |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the shared node service account |
<!-- END_TF_DOCS -->
