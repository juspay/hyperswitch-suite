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
| <a name="module_database"></a> [database](#module\_database) | ../cloud-sql | n/a |
| <a name="module_internal_lb"></a> [internal\_lb](#module\_internal\_lb) | terraform-google-modules/lb-internal/google | 7.1.0 |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-google-modules/kms/google | 4.1.2 |
| <a name="module_locker_group"></a> [locker\_group](#module\_locker\_group) | terraform-google-modules/vm/google//modules/umig | 15.2.1 |
| <a name="module_locker_template"></a> [locker\_template](#module\_locker\_template) | terraform-google-modules/vm/google//modules/instance_template | 15.2.1 |
| <a name="module_service_account"></a> [service\_account](#module\_service\_account) | terraform-google-modules/service-accounts/google | 4.7.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_create_locker_database"></a> [create\_locker\_database](#input\_create\_locker\_database) | Whether to create a dedicated Cloud SQL database for the locker | `bool` | `true` | no |
| <a name="input_database_config"></a> [database\_config](#input\_database\_config) | Configuration for the locker's dedicated Cloud SQL database (composition/cloud-sql) | <pre>object({<br/>    instance_name       = optional(string)<br/>    database_version    = optional(string, "POSTGRES_15")<br/>    tier                = optional(string, "db-custom-2-8192")<br/>    availability_type   = optional(string, "REGIONAL")<br/>    disk_size           = optional(number, 100)<br/>    deletion_protection = optional(bool, true)<br/>    database_name       = optional(string, "locker")<br/>    master_username     = optional(string, "locker_admin")<br/>    master_password     = optional(string)<br/>    encryption_key_name = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Boot disk size in GB | `number` | `50` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Persistent disk type | `string` | `"pd-ssd"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | HTTP path for the locker health check | `string` | `"/health"` | no |
| <a name="input_health_check_port"></a> [health\_check\_port](#input\_health\_check\_port) | Port for the locker health check | `number` | `8080` | no |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | Number of locker instances | `number` | `2` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_lb_subnetwork"></a> [lb\_subnetwork](#input\_lb\_subnetwork) | Self-link of the subnetwork for the internal load balancer's forwarding rule | `string` | n/a | yes |
| <a name="input_locker_image"></a> [locker\_image](#input\_locker\_image) | Self-link or family of the custom image with the card-vault software pre-installed | `string` | n/a | yes |
| <a name="input_locker_port"></a> [locker\_port](#input\_locker\_port) | Port the locker application listens on | `number` | `8080` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | Machine type for locker instances | `string` | `"n2-standard-4"` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Additional instance metadata (e.g. startup-script parameters) | `map(string)` | `{}` | no |
| <a name="input_network"></a> [network](#input\_network) | Self-link of the VPC network | `string` | n/a | yes |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | ID of the VPC network (used by the optional Cloud SQL database, requires Private Service Access) | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where resources are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for regional resources | `string` | n/a | yes |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | Self-link of the subnetwork for locker instances (typically the locker-server tier) | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | Zone to create instances in | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_database_instance_connection_name"></a> [database\_instance\_connection\_name](#output\_database\_instance\_connection\_name) | Cloud SQL Auth Proxy connection name for the locker database, if created |
| <a name="output_internal_lb_ip_address"></a> [internal\_lb\_ip\_address](#output\_internal\_lb\_ip\_address) | IP address of the internal load balancer in front of the locker fleet |
| <a name="output_kms_key_name"></a> [kms\_key\_name](#output\_kms\_key\_name) | Self-link of the KMS key used for the locker's disk and database encryption |
| <a name="output_locker_instance_self_links"></a> [locker\_instance\_self\_links](#output\_locker\_instance\_self\_links) | Self-links of the locker instances |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the shared locker node service account |
<!-- END_TF_DOCS -->
