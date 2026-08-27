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
| <a name="module_node_instances"></a> [node\_instances](#module\_node\_instances) | terraform-google-modules/vm/google//modules/compute_instance | 15.2.1 |
| <a name="module_node_template"></a> [node\_template](#module\_node\_template) | terraform-google-modules/vm/google//modules/instance_template | 15.2.1 |
| <a name="module_seed_discovery"></a> [seed\_discovery](#module\_seed\_discovery) | GoogleCloudPlatform/cloud-functions/google | 0.9.0 |
| <a name="module_service_account"></a> [service\_account](#module\_service\_account) | terraform-google-modules/service-accounts/google | 4.7.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_address.node](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Data disk size in GB per node | `number` | `500` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Persistent disk type | `string` | `"pd-ssd"` | no |
| <a name="input_enable_seed_discovery"></a> [enable\_seed\_discovery](#input\_enable\_seed\_discovery) | Whether to create the seed-discovery Cloud Function | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | Machine type for Cassandra node instances | `string` | `"n2-standard-4"` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Additional instance metadata (e.g. startup-script parameters) | `map(string)` | `{}` | no |
| <a name="input_network"></a> [network](#input\_network) | Self-link of the VPC network | `string` | n/a | yes |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Number of Cassandra node instances | `number` | `3` | no |
| <a name="input_node_image"></a> [node\_image](#input\_node\_image) | Self-link or family of the custom image with Cassandra pre-installed | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where instances are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for regional resources (addresses, instance templates, the seed-discovery function) | `string` | n/a | yes |
| <a name="input_seed_discovery_entrypoint"></a> [seed\_discovery\_entrypoint](#input\_seed\_discovery\_entrypoint) | Entrypoint function name in the seed-discovery source | `string` | `"get_seeds"` | no |
| <a name="input_seed_discovery_runtime"></a> [seed\_discovery\_runtime](#input\_seed\_discovery\_runtime) | Cloud Functions runtime for the seed-discovery function | `string` | `"python312"` | no |
| <a name="input_seed_discovery_source"></a> [seed\_discovery\_source](#input\_seed\_discovery\_source) | GCS location of the seed-discovery function source zip: {bucket, object} | <pre>object({<br/>    bucket     = string<br/>    object     = string<br/>    generation = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | Self-link of the subnetwork (typically the data-stack tier from composition/vpc-network) | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | Zone to create instances in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_node_instance_self_links"></a> [node\_instance\_self\_links](#output\_node\_instance\_self\_links) | Self-links of the Cassandra node instances |
| <a name="output_node_internal_ips"></a> [node\_internal\_ips](#output\_node\_internal\_ips) | Static internal IP addresses assigned to Cassandra nodes |
| <a name="output_seed_discovery_function_uri"></a> [seed\_discovery\_function\_uri](#output\_seed\_discovery\_function\_uri) | HTTPS URI of the seed-discovery function, if enabled |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the shared node service account |
<!-- END_TF_DOCS -->
