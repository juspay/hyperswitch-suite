<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_internal_lb"></a> [internal\_lb](#module\_internal\_lb) | terraform-google-modules/lb-internal/google | 7.1.0 |
| <a name="module_node_group"></a> [node\_group](#module\_node\_group) | terraform-google-modules/vm/google//modules/umig | 15.2.1 |
| <a name="module_node_template"></a> [node\_template](#module\_node\_template) | terraform-google-modules/vm/google//modules/instance_template | 15.2.1 |
| <a name="module_service_account"></a> [service\_account](#module\_service\_account) | terraform-google-modules/service-accounts/google | 4.7.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_attached_disk.data](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk) | resource |
| [google_compute_disk.data](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_boot_disk_size_gb"></a> [boot\_disk\_size\_gb](#input\_boot\_disk\_size\_gb) | Boot disk size in GB | `number` | `50` | no |
| <a name="input_data_disk_size_gb"></a> [data\_disk\_size\_gb](#input\_data\_disk\_size\_gb) | Attached data disk size in GB per node | `number` | `500` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Persistent disk type used for both boot and data disks | `string` | `"pd-ssd"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_http_port"></a> [http\_port](#input\_http\_port) | OpenSearch REST API port | `number` | `9200` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_lb_subnetwork"></a> [lb\_subnetwork](#input\_lb\_subnetwork) | Self-link of the subnetwork for the internal load balancer's forwarding rule | `string` | n/a | yes |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | Machine type for node instances | `string` | `"n2-standard-4"` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Additional instance metadata (e.g. startup-script parameters) | `map(string)` | `{}` | no |
| <a name="input_network"></a> [network](#input\_network) | Self-link of the VPC network | `string` | n/a | yes |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Number of OpenSearch node instances | `number` | `3` | no |
| <a name="input_node_image"></a> [node\_image](#input\_node\_image) | Self-link or family of the custom image with OpenSearch pre-installed | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where instances are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for regional resources | `string` | n/a | yes |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | Self-link of the subnetwork for OpenSearch nodes | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | Zone to create instances in | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_internal_lb_ip_address"></a> [internal\_lb\_ip\_address](#output\_internal\_lb\_ip\_address) | IP address of the internal load balancer in front of the node fleet |
| <a name="output_node_instance_self_links"></a> [node\_instance\_self\_links](#output\_node\_instance\_self\_links) | Self-links of the OpenSearch node instances |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the shared node service account |
<!-- END_TF_DOCS -->
