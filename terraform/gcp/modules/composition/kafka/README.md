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
| <a name="module_broker_instances"></a> [broker\_instances](#module\_broker\_instances) | terraform-google-modules/vm/google//modules/compute_instance | 15.2.1 |
| <a name="module_broker_template"></a> [broker\_template](#module\_broker\_template) | terraform-google-modules/vm/google//modules/instance_template | 15.2.1 |
| <a name="module_controller_instances"></a> [controller\_instances](#module\_controller\_instances) | terraform-google-modules/vm/google//modules/compute_instance | 15.2.1 |
| <a name="module_controller_template"></a> [controller\_template](#module\_controller\_template) | terraform-google-modules/vm/google//modules/instance_template | 15.2.1 |
| <a name="module_service_account"></a> [service\_account](#module\_service\_account) | terraform-google-modules/service-accounts/google | 4.7.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_address.broker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_address.controller](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_broker_count"></a> [broker\_count](#input\_broker\_count) | Number of broker instances | `number` | `3` | no |
| <a name="input_broker_disk_size_gb"></a> [broker\_disk\_size\_gb](#input\_broker\_disk\_size\_gb) | Boot/data disk size in GB for broker instances | `number` | `500` | no |
| <a name="input_broker_image"></a> [broker\_image](#input\_broker\_image) | Self-link or family of the custom image with Kafka broker software pre-installed | `string` | n/a | yes |
| <a name="input_broker_machine_type"></a> [broker\_machine\_type](#input\_broker\_machine\_type) | Machine type for broker instances | `string` | `"n2-standard-4"` | no |
| <a name="input_controller_count"></a> [controller\_count](#input\_controller\_count) | Number of KRaft controller instances (should be odd for quorum) | `number` | `3` | no |
| <a name="input_controller_disk_size_gb"></a> [controller\_disk\_size\_gb](#input\_controller\_disk\_size\_gb) | Boot/data disk size in GB for controller instances | `number` | `100` | no |
| <a name="input_controller_image"></a> [controller\_image](#input\_controller\_image) | Self-link or family of the custom image with the Kafka (KRaft) controller software pre-installed | `string` | n/a | yes |
| <a name="input_controller_machine_type"></a> [controller\_machine\_type](#input\_controller\_machine\_type) | Machine type for controller instances | `string` | `"n2-standard-2"` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Persistent disk type for all instances | `string` | `"pd-ssd"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Additional instance metadata applied to both broker and controller instances (e.g. startup-script parameters) | `map(string)` | `{}` | no |
| <a name="input_network"></a> [network](#input\_network) | Self-link of the VPC network | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where instances are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for regional resources (addresses, instance templates) | `string` | n/a | yes |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | Self-link of the subnetwork (typically the data-stack tier from composition/vpc-network) | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | Zone to create instances in | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_broker_instance_self_links"></a> [broker\_instance\_self\_links](#output\_broker\_instance\_self\_links) | Self-links of the broker instances |
| <a name="output_broker_internal_ips"></a> [broker\_internal\_ips](#output\_broker\_internal\_ips) | Static internal IP addresses assigned to broker instances |
| <a name="output_controller_instance_self_links"></a> [controller\_instance\_self\_links](#output\_controller\_instance\_self\_links) | Self-links of the controller instances |
| <a name="output_controller_internal_ips"></a> [controller\_internal\_ips](#output\_controller\_internal\_ips) | Static internal IP addresses assigned to controller instances |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the shared node service account |
<!-- END_TF_DOCS -->
