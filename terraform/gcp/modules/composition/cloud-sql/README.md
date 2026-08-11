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
| <a name="module_cloud_sql"></a> [cloud\_sql](#module\_cloud\_sql) | terraform-google-modules/sql-db/google//modules/postgresql | 28.1.0 |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-google-modules/kms/google | 4.1.2 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_availability_type"></a> [availability\_type](#input\_availability\_type) | Availability type: ZONAL or REGIONAL (REGIONAL enables HA, the Multi-AZ equivalent) | `string` | `"REGIONAL"` | no |
| <a name="input_backup_start_time"></a> [backup\_start\_time](#input\_backup\_start\_time) | HH:MM start time for the daily automated backup window (UTC) | `string` | `"02:00"` | no |
| <a name="input_database_flags"></a> [database\_flags](#input\_database\_flags) | List of database flags to set on the instance | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Name of the default database to create | `string` | `"hyperswitch"` | no |
| <a name="input_database_version"></a> [database\_version](#input\_database\_version) | PostgreSQL engine version | `string` | `"POSTGRES_15"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Whether to enable deletion protection on the instance | `bool` | `true` | no |
| <a name="input_disk_autoresize"></a> [disk\_autoresize](#input\_disk\_autoresize) | Whether to enable disk autoresize | `bool` | `true` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Disk size in GB | `number` | `100` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Disk type: PD\_SSD or PD\_HDD | `string` | `"PD_SSD"` | no |
| <a name="input_edition"></a> [edition](#input\_edition) | Edition of the instance: ENTERPRISE or ENTERPRISE\_PLUS | `string` | `"ENTERPRISE"` | no |
| <a name="input_enable_point_in_time_recovery"></a> [enable\_point\_in\_time\_recovery](#input\_enable\_point\_in\_time\_recovery) | Whether to enable point-in-time recovery (WAL archiving) | `bool` | `true` | no |
| <a name="input_encryption_key_name"></a> [encryption\_key\_name](#input\_encryption\_key\_name) | Self-link of an existing KMS CryptoKey for disk encryption. Takes precedence over var.kms.create | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Name of the Cloud SQL instance. Defaults to '<environment>-<project\_name>-sql-pg' | `string` | `null` | no |
| <a name="input_kms"></a> [kms](#input\_kms) | CMEK configuration. Set create=true to have this module create a KMS keyring/key for disk encryption | <pre>object({<br/>    create          = optional(bool, false)<br/>    keyring_name    = optional(string)<br/>    key_name        = optional(string, "cloud-sql")<br/>    rotation_period = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | Password for the default database user. Leave null to auto-generate a random password | `string` | `null` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Name of the default database user to create | `string` | `"hyperswitch_admin"` | no |
| <a name="input_module_depends_on"></a> [module\_depends\_on](#input\_module\_depends\_on) | List of resources this module should depend on (e.g. the Private Service Access connection from composition/vpc-network) | `list(any)` | `[]` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | Self-link/ID of the VPC network to attach the instance to (requires Private Service Access to already be configured, see composition/vpc-network) | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the instance is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for labeling and naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_random_instance_name"></a> [random\_instance\_name](#input\_random\_instance\_name) | Whether to append a random suffix to the instance name | `bool` | `false` | no |
| <a name="input_read_replicas"></a> [read\_replicas](#input\_read\_replicas) | List of read replicas to create, in the shape expected by terraform-google-modules/sql-db//modules/postgresql. Cross-region entries are the closest GCP equivalent to an Aurora Global Cluster secondary region. | `any` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the primary Cloud SQL instance | `string` | n/a | yes |
| <a name="input_retained_backups"></a> [retained\_backups](#input\_retained\_backups) | Number of automated backups to retain | `number` | `30` | no |
| <a name="input_tier"></a> [tier](#input\_tier) | Machine tier for the instance (e.g. db-custom-4-16384) | `string` | `"db-custom-2-8192"` | no |
| <a name="input_transaction_log_retention_days"></a> [transaction\_log\_retention\_days](#input\_transaction\_log\_retention\_days) | Number of days of transaction logs to retain for point-in-time recovery | `string` | `"7"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Name of the default database |
| <a name="output_generated_user_password"></a> [generated\_user\_password](#output\_generated\_user\_password) | Auto-generated password for the default user, if master\_password was not set |
| <a name="output_instance_connection_name"></a> [instance\_connection\_name](#output\_instance\_connection\_name) | Connection name for the Cloud SQL Auth Proxy (project:region:instance) |
| <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | Name of the primary Cloud SQL instance |
| <a name="output_instance_self_link"></a> [instance\_self\_link](#output\_instance\_self\_link) | Self-link of the primary instance |
| <a name="output_kms_key_name"></a> [kms\_key\_name](#output\_kms\_key\_name) | Self-link of the KMS key used for disk encryption, if any |
| <a name="output_master_username"></a> [master\_username](#output\_master\_username) | Name of the default database user |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | Private IP address of the primary instance |
| <a name="output_read_replica_instance_names"></a> [read\_replica\_instance\_names](#output\_read\_replica\_instance\_names) | Names of the created read replicas |
<!-- END_TF_DOCS -->
