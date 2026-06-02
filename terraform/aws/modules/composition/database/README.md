<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.31 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.31 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_subnet_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_rds_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_rds_cluster_parameter_group.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_parameter_group) | resource |
| [aws_rds_global_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_global_cluster) | resource |
| [aws_security_group.rds_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | (Optional, Required for Multi-AZ DB cluster) The amount of storage in gibibytes (GiB) to allocate to each DB instance in the Multi-AZ DB cluster | `number` | `null` | no |
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | (Optional) Enable to allow major engine version upgrades when changing engine versions | `bool` | `null` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | (Optional) Specifies whether any cluster modifications are applied immediately, or during the next maintenance window | `bool` | `null` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | (Optional) List of EC2 Availability Zones for the DB cluster storage. RDS automatically assigns 3 AZs if less than 3 are configured | `list(string)` | `null` | no |
| <a name="input_backtrack_window"></a> [backtrack\_window](#input\_backtrack\_window) | (Optional) Target backtrack window, in seconds. Only available for aurora and aurora-mysql engines. To disable backtracking, set to 0 | `number` | `0` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | (Optional) Days to retain backups for. Default 1 | `number` | `7` | no |
| <a name="input_ca_certificate_identifier"></a> [ca\_certificate\_identifier](#input\_ca\_certificate\_identifier) | (Optional) The CA certificate identifier to use for the DB cluster's server certificate | `string` | `null` | no |
| <a name="input_cluster_identifier"></a> [cluster\_identifier](#input\_cluster\_identifier) | (Optional, Forces new resource) The cluster identifier. If omitted, Terraform will assign a random, unique identifier | `string` | `null` | no |
| <a name="input_cluster_identifier_prefix"></a> [cluster\_identifier\_prefix](#input\_cluster\_identifier\_prefix) | (Optional, Forces new resource) Creates a unique cluster identifier beginning with the specified prefix. Conflicts with cluster\_identifier | `string` | `null` | no |
| <a name="input_cluster_instances"></a> [cluster\_instances](#input\_cluster\_instances) | (Optional) Map of cluster instances to create. Each instance can have its own configuration | <pre>map(object({<br/>    identifier                            = optional(string)<br/>    identifier_prefix                     = optional(string)<br/>    instance_class                        = string<br/>    engine                                = optional(string)<br/>    engine_version                        = optional(string)<br/>    publicly_accessible                   = optional(bool, false)<br/>    db_parameter_group_name               = optional(string)<br/>    apply_immediately                     = optional(bool, null)<br/>    monitoring_role_arn                   = optional(string)<br/>    monitoring_interval                   = optional(number, 0)<br/>    promotion_tier                        = optional(number, 0)<br/>    availability_zone                     = optional(string)<br/>    preferred_backup_window               = optional(string)<br/>    preferred_maintenance_window          = optional(string)<br/>    auto_minor_version_upgrade            = optional(bool, true)<br/>    performance_insights_enabled          = optional(bool)<br/>    performance_insights_kms_key_id       = optional(string)<br/>    performance_insights_retention_period = optional(number, 7)<br/>    copy_tags_to_snapshot                 = optional(bool, false)<br/>    ca_cert_identifier                    = optional(string)<br/>    custom_iam_instance_profile           = optional(string)<br/>    force_destroy                         = optional(bool, false)<br/>    tags                                  = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_cluster_scalability_type"></a> [cluster\_scalability\_type](#input\_cluster\_scalability\_type) | (Optional, Forces new resource) Specifies the scalability mode. Valid values: limitless, standard | `string` | `null` | no |
| <a name="input_copy_tags_to_snapshot"></a> [copy\_tags\_to\_snapshot](#input\_copy\_tags\_to\_snapshot) | (Optional) Copy all Cluster tags to snapshots | `bool` | `false` | no |
| <a name="input_create_custom_parameter_group"></a> [create\_custom\_parameter\_group](#input\_create\_custom\_parameter\_group) | (Optional) Whether to create a custom RDS cluster parameter group. Set to true to create a custom parameter group for controlling SSL and other database parameters | `bool` | `false` | no |
| <a name="input_create_db_subnet_group"></a> [create\_db\_subnet\_group](#input\_create\_db\_subnet\_group) | Whether to create a new DB subnet group | `bool` | `true` | no |
| <a name="input_create_global_cluster"></a> [create\_global\_cluster](#input\_create\_global\_cluster) | Whether to create a global cluster for multi-region deployment (only applies to primary cluster) | `bool` | `false` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Whether to create a new security group for RDS | `bool` | `true` | no |
| <a name="input_custom_parameter_group_description"></a> [custom\_parameter\_group\_description](#input\_custom\_parameter\_group\_description) | (Optional) Description for the custom parameter group | `string` | `null` | no |
| <a name="input_custom_parameter_group_family"></a> [custom\_parameter\_group\_family](#input\_custom\_parameter\_group\_family) | (Required when create\_custom\_parameter\_group is true) The family of the DB parameter group. Example: aurora-postgresql15 | `string` | `null` | no |
| <a name="input_custom_parameter_group_name"></a> [custom\_parameter\_group\_name](#input\_custom\_parameter\_group\_name) | (Optional) Name for the custom parameter group. If not provided, will be auto-generated | `string` | `null` | no |
| <a name="input_custom_parameter_group_parameters"></a> [custom\_parameter\_group\_parameters](#input\_custom\_parameter\_group\_parameters) | (Optional) List of parameters to set in the custom parameter group. Example: [{ name = "rds.force\_ssl", value = "0", apply\_method = "immediate" }] to disable SSL | <pre>list(object({<br/>    name         = string<br/>    value        = string<br/>    apply_method = optional(string, "immediate")<br/>  }))</pre> | `[]` | no |
| <a name="input_database_insights_mode"></a> [database\_insights\_mode](#input\_database\_insights\_mode) | (Optional) The mode of Database Insights to enable. Valid values: standard, advanced | `string` | `null` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | (Optional) Name for an automatically created database on cluster creation | `string` | `null` | no |
| <a name="input_db_cluster_instance_class"></a> [db\_cluster\_instance\_class](#input\_db\_cluster\_instance\_class) | (Optional, Required for Multi-AZ DB cluster) The compute and memory capacity of each DB instance in the Multi-AZ DB cluster | `string` | `null` | no |
| <a name="input_db_cluster_parameter_group_name"></a> [db\_cluster\_parameter\_group\_name](#input\_db\_cluster\_parameter\_group\_name) | (Optional) A cluster parameter group to associate with the cluster | `string` | `null` | no |
| <a name="input_db_instance_parameter_group_name"></a> [db\_instance\_parameter\_group\_name](#input\_db\_instance\_parameter\_group\_name) | (Optional) Instance parameter group to associate with all instances of the DB cluster | `string` | `null` | no |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | (Optional) DB subnet group to associate with this DB cluster | `string` | `null` | no |
| <a name="input_db_system_id"></a> [db\_system\_id](#input\_db\_system\_id) | (Optional) For use with RDS Custom | `string` | `null` | no |
| <a name="input_delete_automated_backups"></a> [delete\_automated\_backups](#input\_delete\_automated\_backups) | (Optional) Specifies whether to remove automated backups immediately after the DB cluster is deleted | `bool` | `true` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | (Optional) If the DB cluster should have deletion protection enabled | `bool` | `false` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | (Optional) The ID of the Directory Service Active Directory domain to create the cluster in | `string` | `null` | no |
| <a name="input_domain_iam_role_name"></a> [domain\_iam\_role\_name](#input\_domain\_iam\_role\_name) | (Optional) The name of the IAM role to be used when making API calls to the Directory Service | `string` | `null` | no |
| <a name="input_enable_global_write_forwarding"></a> [enable\_global\_write\_forwarding](#input\_enable\_global\_write\_forwarding) | (Optional) Whether cluster should forward writes to an associated global cluster (secondary clusters only) | `bool` | `false` | no |
| <a name="input_enable_http_endpoint"></a> [enable\_http\_endpoint](#input\_enable\_http\_endpoint) | (Optional) Enable HTTP endpoint (data API). Only valid for some combinations of engine\_mode, engine and engine\_version | `bool` | `false` | no |
| <a name="input_enable_local_write_forwarding"></a> [enable\_local\_write\_forwarding](#input\_enable\_local\_write\_forwarding) | (Optional) Whether read replicas can forward write operations to the writer DB instance | `bool` | `null` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | (Optional) Set of log types to export to CloudWatch. Valid values: audit, error, general, iam-db-auth-error, instance, postgresql, slowquery | `list(string)` | `[]` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | (Required) Name of the database engine to be used for this DB cluster. Valid Values: aurora-mysql, aurora-postgresql, mysql, postgres | `string` | `"aurora-postgresql"` | no |
| <a name="input_engine_lifecycle_support"></a> [engine\_lifecycle\_support](#input\_engine\_lifecycle\_support) | (Optional) The life cycle type for this DB instance. Valid values are open-source-rds-extended-support, open-source-rds-extended-support-disabled | `string` | `"open-source-rds-extended-support"` | no |
| <a name="input_engine_mode"></a> [engine\_mode](#input\_engine\_mode) | (Optional) Database engine mode. Valid values: global, parallelquery, provisioned, serverless | `string` | `"provisioned"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | (Optional) Database engine version. Updating this argument results in an outage | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/sandbox/prod) | `string` | n/a | yes |
| <a name="input_final_snapshot_identifier"></a> [final\_snapshot\_identifier](#input\_final\_snapshot\_identifier) | (Optional) Name of your final DB snapshot when this DB cluster is deleted | `string` | `null` | no |
| <a name="input_global_cluster_identifier"></a> [global\_cluster\_identifier](#input\_global\_cluster\_identifier) | (Optional) Global cluster identifier to which this replication group should belong. If not provided, will be auto-generated | `string` | `null` | no |
| <a name="input_global_deletion_protection"></a> [global\_deletion\_protection](#input\_global\_deletion\_protection) | Whether deletion protection is enabled for the global cluster | `bool` | `true` | no |
| <a name="input_iam_database_authentication_enabled"></a> [iam\_database\_authentication\_enabled](#input\_iam\_database\_authentication\_enabled) | (Optional) Specifies whether IAM database authentication is enabled | `bool` | `false` | no |
| <a name="input_iam_roles"></a> [iam\_roles](#input\_iam\_roles) | (Optional) List of ARNs for the IAM roles to associate to the RDS Cluster | `list(string)` | `[]` | no |
| <a name="input_iops"></a> [iops](#input\_iops) | (Optional) Amount of Provisioned IOPS for each DB instance in the Multi-AZ DB cluster. Must be a multiple between .5 and 50 of the storage amount | `number` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | (Optional) ARN for the KMS encryption key | `string` | `null` | no |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | (Optional) Set to true to allow RDS to manage the master user password in Secrets Manager. Cannot be set if master\_password is provided | `bool` | `null` | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | (Optional, required unless manage\_master\_user\_password is true or snapshot\_identifier is provided) Password for the master DB user | `string` | `null` | no |
| <a name="input_master_user_secret_kms_key_id"></a> [master\_user\_secret\_kms\_key\_id](#input\_master\_user\_secret\_kms\_key\_id) | (Optional) KMS key identifier for encrypting the master user password in Secrets Manager | `string` | `null` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | (Required unless a snapshot\_identifier or replication\_source\_identifier is provided) Username for the master DB user | `string` | `null` | no |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | (Optional) Interval, in seconds, between points when Enhanced Monitoring metrics are collected. Valid Values: 0, 1, 5, 10, 15, 30, 60 | `number` | `0` | no |
| <a name="input_monitoring_role_arn"></a> [monitoring\_role\_arn](#input\_monitoring\_role\_arn) | (Optional) ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs | `string` | `null` | no |
| <a name="input_network_type"></a> [network\_type](#input\_network\_type) | (Optional) Network type of the cluster. Valid values: IPV4, DUAL | `string` | `"IPV4"` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | (Optional) Enables Performance Insights | `bool` | `false` | no |
| <a name="input_performance_insights_kms_key_id"></a> [performance\_insights\_kms\_key\_id](#input\_performance\_insights\_kms\_key\_id) | (Optional) KMS Key ID to encrypt Performance Insights data | `string` | `null` | no |
| <a name="input_performance_insights_retention_period"></a> [performance\_insights\_retention\_period](#input\_performance\_insights\_retention\_period) | (Optional) Amount of time to retain performance insights data. Valid values: 7, month * 31 (1-23), 731 | `number` | `7` | no |
| <a name="input_port"></a> [port](#input\_port) | (Optional) Port on which the DB accepts connections | `number` | `null` | no |
| <a name="input_preferred_backup_window"></a> [preferred\_backup\_window](#input\_preferred\_backup\_window) | (Optional) Daily time range during which automated backups are created (UTC) | `string` | `null` | no |
| <a name="input_preferred_maintenance_window"></a> [preferred\_maintenance\_window](#input\_preferred\_maintenance\_window) | (Optional) Weekly time range during which system maintenance can occur (UTC) | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region where this resource will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_replication_source_identifier"></a> [replication\_source\_identifier](#input\_replication\_source\_identifier) | (Optional) ARN of a source DB cluster or DB instance if this DB cluster is to be created as a Read Replica | `string` | `null` | no |
| <a name="input_restore_to_point_in_time"></a> [restore\_to\_point\_in\_time](#input\_restore\_to\_point\_in\_time) | (Optional) Nested attribute for point in time restore | <pre>object({<br/>    source_cluster_identifier  = optional(string)<br/>    source_cluster_resource_id = optional(string)<br/>    restore_type               = optional(string, "full-copy")<br/>    use_latest_restorable_time = optional(bool, false)<br/>    restore_to_time            = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_s3_import"></a> [s3\_import](#input\_s3\_import) | (Optional) Nested attribute for importing data from S3 | <pre>object({<br/>    bucket_name           = string<br/>    bucket_prefix         = optional(string)<br/>    ingestion_role        = string<br/>    source_engine         = string<br/>    source_engine_version = string<br/>  })</pre> | `null` | no |
| <a name="input_scaling_configuration"></a> [scaling\_configuration](#input\_scaling\_configuration) | (Optional) Nested attribute with scaling properties for Serverless v1. Only valid when engine\_mode is set to serverless | <pre>object({<br/>    auto_pause               = optional(bool, true)<br/>    max_capacity             = optional(number, 16)<br/>    min_capacity             = optional(number, 1)<br/>    seconds_before_timeout   = optional(number, 300)<br/>    seconds_until_auto_pause = optional(number, 300)<br/>    timeout_action           = optional(string, "RollbackCapacityChange")<br/>  })</pre> | `null` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | (Optional) Description for the security group | `string` | `null` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | (Optional) Name for the security group. If not provided, will be auto-generated | `string` | `null` | no |
| <a name="input_serverlessv2_scaling_configuration"></a> [serverlessv2\_scaling\_configuration](#input\_serverlessv2\_scaling\_configuration) | (Optional) Nested attribute with scaling properties for ServerlessV2. Only valid when engine\_mode is set to provisioned | <pre>object({<br/>    max_capacity             = number<br/>    min_capacity             = number<br/>    seconds_until_auto_pause = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | (Optional) Determines whether a final DB snapshot is created before the DB cluster is deleted | `bool` | `false` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | (Optional) Specifies whether or not to create this cluster from a snapshot | `string` | `null` | no |
| <a name="input_source_db_cluster_identifier"></a> [source\_db\_cluster\_identifier](#input\_source\_db\_cluster\_identifier) | ARN of existing cluster to use as primary for global database (only used when use\_existing\_as\_global\_primary is true) | `string` | `null` | no |
| <a name="input_source_region"></a> [source\_region](#input\_source\_region) | (Optional) The source region for an encrypted replica DB cluster | `string` | `null` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | (Optional) Specifies whether the DB cluster is encrypted | `bool` | `true` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | (Optional) Specifies the storage type. Valid values for Aurora: aurora-iopt1. Valid values for Multi-AZ: io1, io2 | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for RDS DB subnet group | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_use_existing_as_global_primary"></a> [use\_existing\_as\_global\_primary](#input\_use\_existing\_as\_global\_primary) | Whether to use existing cluster as primary for global database (links existing cluster instead of creating new) | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where resources will be created | `string` | n/a | yes |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | (Optional) List of VPC security groups to associate with the Cluster | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zones"></a> [availability\_zones](#output\_availability\_zones) | Availability zones of the cluster |
| <a name="output_backup_retention_period"></a> [backup\_retention\_period](#output\_backup\_retention\_period) | Backup retention period |
| <a name="output_ca_certificate_identifier"></a> [ca\_certificate\_identifier](#output\_ca\_certificate\_identifier) | CA identifier of the CA certificate used for the DB instance's server certificate |
| <a name="output_ca_certificate_valid_till"></a> [ca\_certificate\_valid\_till](#output\_ca\_certificate\_valid\_till) | Expiration date of the DB instance's server certificate |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | Amazon Resource Name (ARN) of cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | RDS Cluster Identifier |
| <a name="output_cluster_identifier"></a> [cluster\_identifier](#output\_cluster\_identifier) | RDS Cluster Identifier |
| <a name="output_cluster_instance_arns"></a> [cluster\_instance\_arns](#output\_cluster\_instance\_arns) | Map of cluster instance ARNs |
| <a name="output_cluster_instance_availability_zones"></a> [cluster\_instance\_availability\_zones](#output\_cluster\_instance\_availability\_zones) | Map of cluster instance availability zones |
| <a name="output_cluster_instance_endpoints"></a> [cluster\_instance\_endpoints](#output\_cluster\_instance\_endpoints) | Map of cluster instance endpoints |
| <a name="output_cluster_instance_ids"></a> [cluster\_instance\_ids](#output\_cluster\_instance\_ids) | Map of cluster instance identifiers |
| <a name="output_cluster_instance_writer_status"></a> [cluster\_instance\_writer\_status](#output\_cluster\_instance\_writer\_status) | Map indicating if each instance is a writer |
| <a name="output_cluster_members"></a> [cluster\_members](#output\_cluster\_members) | List of RDS Instances that are a part of this cluster |
| <a name="output_cluster_resource_id"></a> [cluster\_resource\_id](#output\_cluster\_resource\_id) | RDS Cluster Resource ID |
| <a name="output_custom_parameter_group_arn"></a> [custom\_parameter\_group\_arn](#output\_custom\_parameter\_group\_arn) | ARN of the custom RDS cluster parameter group (if created) |
| <a name="output_custom_parameter_group_id"></a> [custom\_parameter\_group\_id](#output\_custom\_parameter\_group\_id) | ID of the custom RDS cluster parameter group (if created) |
| <a name="output_custom_parameter_group_name"></a> [custom\_parameter\_group\_name](#output\_custom\_parameter\_group\_name) | Name of the custom RDS cluster parameter group (if created) |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Database name |
| <a name="output_db_subnet_group_arn"></a> [db\_subnet\_group\_arn](#output\_db\_subnet\_group\_arn) | ARN of the DB subnet group |
| <a name="output_db_subnet_group_id"></a> [db\_subnet\_group\_id](#output\_db\_subnet\_group\_id) | ID of the DB subnet group |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | Name of the DB subnet group |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | DNS address of the RDS instance |
| <a name="output_engine"></a> [engine](#output\_engine) | Database engine |
| <a name="output_engine_version_actual"></a> [engine\_version\_actual](#output\_engine\_version\_actual) | Running version of the database |
| <a name="output_global_cluster_arn"></a> [global\_cluster\_arn](#output\_global\_cluster\_arn) | ARN of the Global Cluster |
| <a name="output_global_cluster_id"></a> [global\_cluster\_id](#output\_global\_cluster\_id) | Global Cluster Identifier |
| <a name="output_global_cluster_identifier"></a> [global\_cluster\_identifier](#output\_global\_cluster\_identifier) | Global Cluster Identifier name |
| <a name="output_global_writer_endpoint"></a> [global\_writer\_endpoint](#output\_global\_writer\_endpoint) | Global writer endpoint for the Aurora Global Database (use this for applications) |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | Route53 Hosted Zone ID of the endpoint |
| <a name="output_is_primary_cluster"></a> [is\_primary\_cluster](#output\_is\_primary\_cluster) | Whether this cluster is the primary cluster in the global database |
| <a name="output_is_secondary_cluster"></a> [is\_secondary\_cluster](#output\_is\_secondary\_cluster) | Whether this cluster is a secondary/replica cluster in the global database |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | KMS key identifier for encryption |
| <a name="output_master_user_secret"></a> [master\_user\_secret](#output\_master\_user\_secret) | Block that specifies the master user secret. Only available when manage\_master\_user\_password is set to true |
| <a name="output_master_username"></a> [master\_username](#output\_master\_username) | Master username for the database |
| <a name="output_port"></a> [port](#output\_port) | Database port |
| <a name="output_preferred_backup_window"></a> [preferred\_backup\_window](#output\_preferred\_backup\_window) | Daily time range during which the backups happen |
| <a name="output_preferred_maintenance_window"></a> [preferred\_maintenance\_window](#output\_preferred\_maintenance\_window) | Maintenance window |
| <a name="output_reader_endpoint"></a> [reader\_endpoint](#output\_reader\_endpoint) | Read-only endpoint for the Aurora cluster, automatically load-balanced across replicas |
| <a name="output_replication_source_identifier"></a> [replication\_source\_identifier](#output\_replication\_source\_identifier) | ARN of the source DB cluster or DB instance if this DB cluster is created as a Read Replica |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the security group created for RDS |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group created for RDS |
| <a name="output_security_group_name"></a> [security\_group\_name](#output\_security\_group\_name) | Name of the security group created for RDS |
| <a name="output_storage_encrypted"></a> [storage\_encrypted](#output\_storage\_encrypted) | Specifies whether the DB cluster is encrypted |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | Map of tags assigned to the resource, including those inherited from the provider |
<!-- END_TF_DOCS -->