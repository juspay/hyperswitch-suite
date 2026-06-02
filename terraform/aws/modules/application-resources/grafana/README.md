<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_database"></a> [database](#module\_database) | git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/database | database-v0.1.4 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.customer_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_openid_connect_provider.oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_assume_role_statements"></a> [additional\_assume\_role\_statements](#input\_additional\_assume\_role\_statements) | Additional IAM assume role policy statements to append | `list(any)` | `[]` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Application name | `string` | `"grafana"` | no |
| <a name="input_assume_role_principals"></a> [assume\_role\_principals](#input\_assume\_role\_principals) | List of AWS principal ARNs allowed to assume this role (e.g., ['arn:aws:iam::123456789012:root']) | `list(string)` | `[]` | no |
| <a name="input_aws_managed_policy_names"></a> [aws\_managed\_policy\_names](#input\_aws\_managed\_policy\_names) | List of AWS managed policy names to attach | `list(string)` | `[]` | no |
| <a name="input_cluster_service_accounts"></a> [cluster\_service\_accounts](#input\_cluster\_service\_accounts) | Map of EKS cluster names to their respective list of Kubernetes service accounts (namespace and service account name) | <pre>map(list(object({<br/>    namespace = string<br/>    name      = string<br/>  })))</pre> | `{}` | no |
| <a name="input_create_database"></a> [create\_database](#input\_create\_database) | Whether to create a database for Grafana | `bool` | `false` | no |
| <a name="input_customer_managed_policy_arns"></a> [customer\_managed\_policy\_arns](#input\_customer\_managed\_policy\_arns) | List of customer managed policy ARNs to attach | `list(string)` | `[]` | no |
| <a name="input_database_allocated_storage"></a> [database\_allocated\_storage](#input\_database\_allocated\_storage) | Amount of storage in GiB to allocate (for Multi-AZ DB cluster) | `number` | `null` | no |
| <a name="input_database_allow_major_version_upgrade"></a> [database\_allow\_major\_version\_upgrade](#input\_database\_allow\_major\_version\_upgrade) | Enable to allow major engine version upgrades | `bool` | `null` | no |
| <a name="input_database_apply_immediately"></a> [database\_apply\_immediately](#input\_database\_apply\_immediately) | Specifies whether cluster modifications are applied immediately or during next maintenance window | `bool` | `null` | no |
| <a name="input_database_availability_zones"></a> [database\_availability\_zones](#input\_database\_availability\_zones) | List of EC2 Availability Zones for the DB cluster storage | `list(string)` | `null` | no |
| <a name="input_database_backtrack_window"></a> [database\_backtrack\_window](#input\_database\_backtrack\_window) | Target backtrack window in seconds (0 to disable, max 259200 for 72 hours) | `number` | `0` | no |
| <a name="input_database_backup_retention_period"></a> [database\_backup\_retention\_period](#input\_database\_backup\_retention\_period) | Days to retain backups for | `number` | `7` | no |
| <a name="input_database_ca_certificate_identifier"></a> [database\_ca\_certificate\_identifier](#input\_database\_ca\_certificate\_identifier) | CA certificate identifier to use for the DB cluster's server certificate | `string` | `null` | no |
| <a name="input_database_cluster_identifier"></a> [database\_cluster\_identifier](#input\_database\_cluster\_identifier) | Custom cluster identifier for the database. If null, auto-generated | `string` | `null` | no |
| <a name="input_database_cluster_instances"></a> [database\_cluster\_instances](#input\_database\_cluster\_instances) | Map of cluster instances to create | <pre>map(object({<br/>    identifier                            = optional(string)<br/>    identifier_prefix                     = optional(string)<br/>    instance_class                        = string<br/>    engine                                = optional(string)<br/>    engine_version                        = optional(string)<br/>    publicly_accessible                   = optional(bool, false)<br/>    db_parameter_group_name               = optional(string)<br/>    apply_immediately                     = optional(bool, null)<br/>    monitoring_role_arn                   = optional(string)<br/>    monitoring_interval                   = optional(number, 0)<br/>    promotion_tier                        = optional(number, 0)<br/>    availability_zone                     = optional(string)<br/>    preferred_backup_window               = optional(string)<br/>    preferred_maintenance_window          = optional(string)<br/>    auto_minor_version_upgrade            = optional(bool, true)<br/>    performance_insights_enabled          = optional(bool)<br/>    performance_insights_kms_key_id       = optional(string)<br/>    performance_insights_retention_period = optional(number, 7)<br/>    copy_tags_to_snapshot                 = optional(bool, false)<br/>    ca_cert_identifier                    = optional(string)<br/>    custom_iam_instance_profile           = optional(string)<br/>    force_destroy                         = optional(bool, false)<br/>    tags                                  = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_database_copy_tags_to_snapshot"></a> [database\_copy\_tags\_to\_snapshot](#input\_database\_copy\_tags\_to\_snapshot) | Copy all Cluster tags to snapshots | `bool` | `false` | no |
| <a name="input_database_create_custom_parameter_group"></a> [database\_create\_custom\_parameter\_group](#input\_database\_create\_custom\_parameter\_group) | Whether to create a custom parameter group | `bool` | `false` | no |
| <a name="input_database_create_db_subnet_group"></a> [database\_create\_db\_subnet\_group](#input\_database\_create\_db\_subnet\_group) | Whether to create a new DB subnet group. Set to false to reuse an existing subnet group | `bool` | `true` | no |
| <a name="input_database_create_global_cluster"></a> [database\_create\_global\_cluster](#input\_database\_create\_global\_cluster) | Whether to create a global cluster for multi-region deployment | `bool` | `false` | no |
| <a name="input_database_create_security_group"></a> [database\_create\_security\_group](#input\_database\_create\_security\_group) | Whether to create a security group for the database | `bool` | `true` | no |
| <a name="input_database_custom_parameter_group_description"></a> [database\_custom\_parameter\_group\_description](#input\_database\_custom\_parameter\_group\_description) | Description for the custom parameter group | `string` | `null` | no |
| <a name="input_database_custom_parameter_group_family"></a> [database\_custom\_parameter\_group\_family](#input\_database\_custom\_parameter\_group\_family) | Family for the custom parameter group | `string` | `null` | no |
| <a name="input_database_custom_parameter_group_name"></a> [database\_custom\_parameter\_group\_name](#input\_database\_custom\_parameter\_group\_name) | Custom name for the parameter group | `string` | `null` | no |
| <a name="input_database_custom_parameter_group_parameters"></a> [database\_custom\_parameter\_group\_parameters](#input\_database\_custom\_parameter\_group\_parameters) | List of parameters for custom parameter group | <pre>list(object({<br/>    name         = string<br/>    value        = string<br/>    apply_method = optional(string, "immediate")<br/>  }))</pre> | `[]` | no |
| <a name="input_database_database_insights_mode"></a> [database\_database\_insights\_mode](#input\_database\_database\_insights\_mode) | Mode of Database Insights. Valid values: standard, advanced | `string` | `null` | no |
| <a name="input_database_db_cluster_instance_class"></a> [database\_db\_cluster\_instance\_class](#input\_database\_db\_cluster\_instance\_class) | Compute and memory capacity of each DB instance in Multi-AZ cluster | `string` | `null` | no |
| <a name="input_database_db_cluster_parameter_group_name"></a> [database\_db\_cluster\_parameter\_group\_name](#input\_database\_db\_cluster\_parameter\_group\_name) | Existing cluster parameter group to associate with the cluster | `string` | `null` | no |
| <a name="input_database_db_instance_parameter_group_name"></a> [database\_db\_instance\_parameter\_group\_name](#input\_database\_db\_instance\_parameter\_group\_name) | Instance parameter group to associate with all instances of the DB cluster | `string` | `null` | no |
| <a name="input_database_db_subnet_group_name"></a> [database\_db\_subnet\_group\_name](#input\_database\_db\_subnet\_group\_name) | Existing DB subnet group name to reuse (if create\_db\_subnet\_group is false) | `string` | `null` | no |
| <a name="input_database_delete_automated_backups"></a> [database\_delete\_automated\_backups](#input\_database\_delete\_automated\_backups) | Whether to remove automated backups immediately after cluster deletion | `bool` | `true` | no |
| <a name="input_database_deletion_protection"></a> [database\_deletion\_protection](#input\_database\_deletion\_protection) | Whether to enable deletion protection | `bool` | `false` | no |
| <a name="input_database_enable_global_write_forwarding"></a> [database\_enable\_global\_write\_forwarding](#input\_database\_enable\_global\_write\_forwarding) | Whether cluster should forward writes to an associated global cluster | `bool` | `false` | no |
| <a name="input_database_enable_http_endpoint"></a> [database\_enable\_http\_endpoint](#input\_database\_enable\_http\_endpoint) | Enable HTTP endpoint (Data API) | `bool` | `false` | no |
| <a name="input_database_enabled_cloudwatch_logs_exports"></a> [database\_enabled\_cloudwatch\_logs\_exports](#input\_database\_enabled\_cloudwatch\_logs\_exports) | List of log types to export to CloudWatch | `list(string)` | `[]` | no |
| <a name="input_database_engine"></a> [database\_engine](#input\_database\_engine) | Database engine to use | `string` | `"aurora-postgresql"` | no |
| <a name="input_database_engine_lifecycle_support"></a> [database\_engine\_lifecycle\_support](#input\_database\_engine\_lifecycle\_support) | The life cycle type for this DB instance. Valid values: open-source-rds-extended-support, open-source-rds-extended-support-disabled | `string` | `null` | no |
| <a name="input_database_engine_mode"></a> [database\_engine\_mode](#input\_database\_engine\_mode) | Database engine mode. Valid values: global, parallelquery, provisioned, serverless | `string` | `"provisioned"` | no |
| <a name="input_database_engine_version"></a> [database\_engine\_version](#input\_database\_engine\_version) | Database engine version | `string` | `null` | no |
| <a name="input_database_final_snapshot_identifier"></a> [database\_final\_snapshot\_identifier](#input\_database\_final\_snapshot\_identifier) | Name of the final DB snapshot when cluster is deleted | `string` | `null` | no |
| <a name="input_database_global_cluster_identifier"></a> [database\_global\_cluster\_identifier](#input\_database\_global\_cluster\_identifier) | Global cluster identifier to which this cluster should belong | `string` | `null` | no |
| <a name="input_database_global_deletion_protection"></a> [database\_global\_deletion\_protection](#input\_database\_global\_deletion\_protection) | Whether deletion protection is enabled for the global cluster | `bool` | `true` | no |
| <a name="input_database_iam_database_authentication_enabled"></a> [database\_iam\_database\_authentication\_enabled](#input\_database\_iam\_database\_authentication\_enabled) | Whether to enable IAM database authentication | `bool` | `false` | no |
| <a name="input_database_iam_roles"></a> [database\_iam\_roles](#input\_database\_iam\_roles) | List of ARNs for IAM roles to associate with the RDS Cluster | `list(string)` | `[]` | no |
| <a name="input_database_iops"></a> [database\_iops](#input\_database\_iops) | Provisioned IOPS for each DB instance in Multi-AZ cluster | `number` | `null` | no |
| <a name="input_database_kms_key_id"></a> [database\_kms\_key\_id](#input\_database\_kms\_key\_id) | KMS key ID for encryption | `string` | `null` | no |
| <a name="input_database_manage_master_user_password"></a> [database\_manage\_master\_user\_password](#input\_database\_manage\_master\_user\_password) | Whether to allow RDS to manage the master user password in Secrets Manager | `bool` | `true` | no |
| <a name="input_database_master_password"></a> [database\_master\_password](#input\_database\_master\_password) | Master password for the database | `string` | `null` | no |
| <a name="input_database_master_user_secret_kms_key_id"></a> [database\_master\_user\_secret\_kms\_key\_id](#input\_database\_master\_user\_secret\_kms\_key\_id) | KMS key identifier for encrypting the master user password in Secrets Manager | `string` | `null` | no |
| <a name="input_database_master_username"></a> [database\_master\_username](#input\_database\_master\_username) | Master username for the database | `string` | `null` | no |
| <a name="input_database_monitoring_interval"></a> [database\_monitoring\_interval](#input\_database\_monitoring\_interval) | Interval in seconds between Enhanced Monitoring metrics collection. Valid: 0, 1, 5, 10, 15, 30, 60 | `number` | `0` | no |
| <a name="input_database_monitoring_role_arn"></a> [database\_monitoring\_role\_arn](#input\_database\_monitoring\_role\_arn) | ARN for IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch | `string` | `null` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Name of the database to create | `string` | `null` | no |
| <a name="input_database_network_type"></a> [database\_network\_type](#input\_database\_network\_type) | Network type of the cluster. Valid values: IPV4, DUAL | `string` | `null` | no |
| <a name="input_database_performance_insights_enabled"></a> [database\_performance\_insights\_enabled](#input\_database\_performance\_insights\_enabled) | Whether to enable Performance Insights | `bool` | `false` | no |
| <a name="input_database_performance_insights_kms_key_id"></a> [database\_performance\_insights\_kms\_key\_id](#input\_database\_performance\_insights\_kms\_key\_id) | KMS key ID for Performance Insights encryption | `string` | `null` | no |
| <a name="input_database_performance_insights_retention_period"></a> [database\_performance\_insights\_retention\_period](#input\_database\_performance\_insights\_retention\_period) | Retention period for Performance Insights data | `number` | `7` | no |
| <a name="input_database_port"></a> [database\_port](#input\_database\_port) | Port on which the DB accepts connections | `number` | `null` | no |
| <a name="input_database_preferred_backup_window"></a> [database\_preferred\_backup\_window](#input\_database\_preferred\_backup\_window) | Daily time range during which automated backups are created (UTC) | `string` | `null` | no |
| <a name="input_database_preferred_maintenance_window"></a> [database\_preferred\_maintenance\_window](#input\_database\_preferred\_maintenance\_window) | Weekly time range during which system maintenance can occur (UTC) | `string` | `null` | no |
| <a name="input_database_scaling_configuration"></a> [database\_scaling\_configuration](#input\_database\_scaling\_configuration) | Scaling configuration for Serverless v1 (only valid when engine\_mode is serverless) | <pre>object({<br/>    auto_pause               = optional(bool, true)<br/>    max_capacity             = optional(number, 16)<br/>    min_capacity             = optional(number, 1)<br/>    seconds_before_timeout   = optional(number, 300)<br/>    seconds_until_auto_pause = optional(number, 300)<br/>    timeout_action           = optional(string, "RollbackCapacityChange")<br/>  })</pre> | `null` | no |
| <a name="input_database_security_group_description"></a> [database\_security\_group\_description](#input\_database\_security\_group\_description) | Custom description for the database security group | `string` | `null` | no |
| <a name="input_database_security_group_name"></a> [database\_security\_group\_name](#input\_database\_security\_group\_name) | Custom name for the database security group (if create\_security\_group is true) | `string` | `null` | no |
| <a name="input_database_serverlessv2_scaling_configuration"></a> [database\_serverlessv2\_scaling\_configuration](#input\_database\_serverlessv2\_scaling\_configuration) | Serverless v2 scaling configuration | <pre>object({<br/>    max_capacity             = number<br/>    min_capacity             = number<br/>    seconds_until_auto_pause = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_database_skip_final_snapshot"></a> [database\_skip\_final\_snapshot](#input\_database\_skip\_final\_snapshot) | Whether to skip final snapshot on deletion | `bool` | `false` | no |
| <a name="input_database_snapshot_identifier"></a> [database\_snapshot\_identifier](#input\_database\_snapshot\_identifier) | Specifies whether to create this cluster from a snapshot | `string` | `null` | no |
| <a name="input_database_source_db_cluster_identifier"></a> [database\_source\_db\_cluster\_identifier](#input\_database\_source\_db\_cluster\_identifier) | ARN of existing cluster to use as primary for global database | `string` | `null` | no |
| <a name="input_database_storage_encrypted"></a> [database\_storage\_encrypted](#input\_database\_storage\_encrypted) | Whether to encrypt storage | `bool` | `true` | no |
| <a name="input_database_storage_type"></a> [database\_storage\_type](#input\_database\_storage\_type) | Storage type. Valid values for Aurora: aurora-iopt1. Valid values for Multi-AZ: io1, io2 | `string` | `null` | no |
| <a name="input_database_subnet_ids"></a> [database\_subnet\_ids](#input\_database\_subnet\_ids) | List of subnet IDs for the database subnet group (required if create\_database is true) | `list(string)` | `[]` | no |
| <a name="input_database_use_existing_as_global_primary"></a> [database\_use\_existing\_as\_global\_primary](#input\_database\_use\_existing\_as\_global\_primary) | Whether to use existing cluster as primary for global database | `bool` | `false` | no |
| <a name="input_database_vpc_id"></a> [database\_vpc\_id](#input\_database\_vpc\_id) | VPC ID where the database will be created (required if create\_database is true) | `string` | `null` | no |
| <a name="input_database_vpc_security_group_ids"></a> [database\_vpc\_security\_group\_ids](#input\_database\_vpc\_security\_group\_ids) | List of VPC security group IDs to associate with the database | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_force_detach_policies"></a> [force\_detach\_policies](#input\_force\_detach\_policies) | Whether to force detaching policies when destroying the role | `bool` | `true` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration for the role (in seconds) | `number` | `3600` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `null` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Custom IAM role description | `string` | `null` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Custom IAM role name. If null, auto-generated as {environment}-{project}-{app}-role | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | IAM role path | `string` | `"/"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | AWS account ID |
| <a name="output_assume_role_principals_enabled"></a> [assume\_role\_principals\_enabled](#output\_assume\_role\_principals\_enabled) | Whether assume role principals feature is enabled |
| <a name="output_aws_managed_policies_enabled"></a> [aws\_managed\_policies\_enabled](#output\_aws\_managed\_policies\_enabled) | Whether AWS managed policy attachments feature is enabled |
| <a name="output_customer_managed_policies_enabled"></a> [customer\_managed\_policies\_enabled](#output\_customer\_managed\_policies\_enabled) | Whether customer managed policy attachments feature is enabled |
| <a name="output_database_cluster_arn"></a> [database\_cluster\_arn](#output\_database\_cluster\_arn) | ARN of the RDS cluster (if database is created) |
| <a name="output_database_cluster_id"></a> [database\_cluster\_id](#output\_database\_cluster\_id) | RDS Cluster Identifier (if database is created) |
| <a name="output_database_cluster_instance_endpoints"></a> [database\_cluster\_instance\_endpoints](#output\_database\_cluster\_instance\_endpoints) | Map of cluster instance endpoints (if database is created) |
| <a name="output_database_cluster_instance_ids"></a> [database\_cluster\_instance\_ids](#output\_database\_cluster\_instance\_ids) | Map of cluster instance identifiers (if database is created) |
| <a name="output_database_enabled"></a> [database\_enabled](#output\_database\_enabled) | Whether database feature is enabled |
| <a name="output_database_endpoint"></a> [database\_endpoint](#output\_database\_endpoint) | Writer endpoint for the database (if database is created) |
| <a name="output_database_master_username"></a> [database\_master\_username](#output\_database\_master\_username) | Master username for the database (if database is created) |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Name of the database (if database is created) |
| <a name="output_database_port"></a> [database\_port](#output\_database\_port) | Port for the database (if database is created) |
| <a name="output_database_reader_endpoint"></a> [database\_reader\_endpoint](#output\_database\_reader\_endpoint) | Reader endpoint for the database (if database is created) |
| <a name="output_database_security_group_id"></a> [database\_security\_group\_id](#output\_database\_security\_group\_id) | ID of the security group for the database (if created) |
| <a name="output_oidc_enabled"></a> [oidc\_enabled](#output\_oidc\_enabled) | Whether OIDC/IRSA feature is enabled |
| <a name="output_region"></a> [region](#output\_region) | AWS region where resources are created |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the IAM role for Grafana application |
| <a name="output_role_id"></a> [role\_id](#output\_role\_id) | ID of the IAM role for Grafana application |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the IAM role for Grafana application |
<!-- END_TF_DOCS -->