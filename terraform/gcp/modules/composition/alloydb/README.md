<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.23, < 8.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 7.46.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_alloydb"></a> [alloydb](#module\_alloydb) | GoogleCloudPlatform/alloy-db/google | ~> 8.0 |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-google-modules/kms/google | 4.1.2 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_secret_manager_secret.master_password](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_version.master_password](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [random_password.master](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allocated_ip_range"></a> [allocated\_ip\_range](#input\_allocated\_ip\_range) | Name (not CIDR) of the Private Service Access reserved IP range - composition/vpc-network exposes this as private\_service\_access\_range\_name | `string` | n/a | yes |
| <a name="input_automated_backup_enabled"></a> [automated\_backup\_enabled](#input\_automated\_backup\_enabled) | Whether to enable daily automated (snapshot) backups | `bool` | `true` | no |
| <a name="input_automated_backup_retention_count"></a> [automated\_backup\_retention\_count](#input\_automated\_backup\_retention\_count) | Number of automated daily backups to retain | `number` | `14` | no |
| <a name="input_automated_backup_start_hour"></a> [automated\_backup\_start\_hour](#input\_automated\_backup\_start\_hour) | UTC hour (0-23) the daily automated backup window starts | `number` | `2` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | AlloyDB cluster ID. Defaults to '<environment>-<project\_name>-alloydb' | `string` | `null` | no |
| <a name="input_continuous_backup_enabled"></a> [continuous\_backup\_enabled](#input\_continuous\_backup\_enabled) | Whether to enable continuous backup (AlloyDB's point-in-time recovery equivalent) | `bool` | `true` | no |
| <a name="input_continuous_backup_recovery_window_days"></a> [continuous\_backup\_recovery\_window\_days](#input\_continuous\_backup\_recovery\_window\_days) | Number of days of continuous backup / PITR window to retain | `number` | `14` | no |
| <a name="input_database_version"></a> [database\_version](#input\_database\_version) | PostgreSQL engine version | `string` | `"POSTGRES_15"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Whether to enable deletion protection on the cluster | `bool` | `true` | no |
| <a name="input_encryption_key_name"></a> [encryption\_key\_name](#input\_encryption\_key\_name) | Self-link of an existing KMS CryptoKey for cluster encryption. Takes precedence over var.kms.create | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_kms"></a> [kms](#input\_kms) | CMEK configuration. Set create=true to have this module create a KMS keyring/key for cluster encryption | <pre>object({<br/>    create          = optional(bool, false)<br/>    keyring_name    = optional(string)<br/>    key_name        = optional(string, "alloydb")<br/>    rotation_period = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | Password for the bootstrap admin user. Leave null to auto-generate a random one (AlloyDB has no built-in auto-generation like Cloud SQL - this module replicates it with its own random\_password resource) | `string` | `null` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Name of the cluster's bootstrap admin user | `string` | `"hyperswitch_admin"` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | Self-link/ID of the VPC network to attach the cluster to (requires Private Service Access to already be configured, see composition/vpc-network) | `string` | n/a | yes |
| <a name="input_primary_availability_type"></a> [primary\_availability\_type](#input\_primary\_availability\_type) | ZONAL (single zone, no standby - cheapest, dev/test only per Google's own guidance) or REGIONAL (active+standby across zones, automated failover - the production-grade default) | `string` | `"REGIONAL"` | no |
| <a name="input_primary_cpu_count"></a> [primary\_cpu\_count](#input\_primary\_cpu\_count) | vCPU count for the primary instance. Valid discrete values (N2/N2D families): 2, 4, 8, 16, 32, 48, 64, ... - 1 is only available on the region-limited C4A family, so 2 is the practical cheapest default. Bump meaningfully (8+) for real production load. | `number` | `2` | no |
| <a name="input_primary_machine_type"></a> [primary\_machine\_type](#input\_primary\_machine\_type) | Explicit machine type for the primary instance, overriding primary\_cpu\_count's implied sizing. Leave null to size purely off primary\_cpu\_count. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the cluster is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for labeling and naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_read_pool_instances"></a> [read\_pool\_instances](#input\_read\_pool\_instances) | Read pool instances to create under this same cluster, for read scaling / production HA. Empty by default (minimal single-instance deployment) - populate for a production-grade setup, e.g. [{ instance\_id = "read-1", node\_count = 2, cpu\_count = 4 }]. | <pre>list(object({<br/>    instance_id = string<br/>    node_count  = number<br/>    cpu_count   = optional(number, 2)<br/>  }))</pre> | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | Region (AlloyDB 'location') for the cluster | `string` | n/a | yes |
| <a name="input_secret_manager"></a> [secret\_manager](#input\_secret\_manager) | Set create=true to have this module store the auto-generated master password in Secret Manager. Only takes effect when master\_password is left unset. | <pre>object({<br/>    create    = optional(bool, false)<br/>    secret_id = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | AlloyDB cluster ID |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Fully-qualified cluster resource name |
| <a name="output_generated_user_password"></a> [generated\_user\_password](#output\_generated\_user\_password) | The master password in effect (module-generated if master\_password was left unset) |
| <a name="output_kms_key_name"></a> [kms\_key\_name](#output\_kms\_key\_name) | Self-link of the KMS key used for cluster encryption, if any |
| <a name="output_master_username"></a> [master\_username](#output\_master\_username) | Name of the bootstrap admin user |
| <a name="output_primary_instance_id"></a> [primary\_instance\_id](#output\_primary\_instance\_id) | ID of the primary instance |
| <a name="output_primary_instance_ip"></a> [primary\_instance\_ip](#output\_primary\_instance\_ip) | Private IP address of the primary instance - use this as the app's DB host |
| <a name="output_read_instance_ids"></a> [read\_instance\_ids](#output\_read\_instance\_ids) | IDs of the read pool instances, if any |
| <a name="output_read_instance_ips"></a> [read\_instance\_ips](#output\_read\_instance\_ips) | Private IP addresses of the read pool instances, if any |
| <a name="output_secret_manager_secret_id"></a> [secret\_manager\_secret\_id](#output\_secret\_manager\_secret\_id) | Secret ID of the Secret Manager secret holding the generated master password, if secret\_manager.create was set |
| <a name="output_secret_manager_secret_name"></a> [secret\_manager\_secret\_name](#output\_secret\_manager\_secret\_name) | Fully-qualified name (projects/.../secrets/...) of the Secret Manager secret, if created |
<!-- END_TF_DOCS -->