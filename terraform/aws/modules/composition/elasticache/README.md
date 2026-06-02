<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.31 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.31 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_elasticache_global_replication_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_global_replication_group) | resource |
| [aws_elasticache_replication_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |
| [aws_elasticache_subnet_group.elasticache_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |
| [aws_security_group.elasticache_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | (Optional) Specifies whether any modifications are applied immediately, or during the next maintenance window | `bool` | `false` | no |
| <a name="input_at_rest_encryption_enabled"></a> [at\_rest\_encryption\_enabled](#input\_at\_rest\_encryption\_enabled) | (Optional) Whether to enable encryption at rest. When engine is redis, default is false. When engine is valkey, default is true | `bool` | `false` | no |
| <a name="input_auth_token"></a> [auth\_token](#input\_auth\_token) | (Optional) Password used to access a password protected server. Can be specified only if transit\_encryption\_enabled = true | `string` | `null` | no |
| <a name="input_auth_token_update_strategy"></a> [auth\_token\_update\_strategy](#input\_auth\_token\_update\_strategy) | (Optional) Strategy to use when updating auth\_token. Valid values are SET, ROTATE, and DELETE. If omitted, AWS defaults to ROTATE | `string` | `null` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | (Optional) Specifies whether minor version engine upgrades will be applied automatically during the maintenance window. Only for engine types redis/valkey and engine version 6+ | `bool` | `true` | no |
| <a name="input_automatic_failover_enabled"></a> [automatic\_failover\_enabled](#input\_automatic\_failover\_enabled) | (Optional) Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails | `bool` | `true` | no |
| <a name="input_cluster_mode"></a> [cluster\_mode](#input\_cluster\_mode) | (Optional) Specifies whether cluster mode is enabled or disabled. Valid values are enabled, disabled, or compatible | `string` | `"enabled"` | no |
| <a name="input_create_elasticache_subnet_group"></a> [create\_elasticache\_subnet\_group](#input\_create\_elasticache\_subnet\_group) | Whether to create an ElastiCache subnet group | `bool` | `true` | no |
| <a name="input_create_global_replication_group"></a> [create\_global\_replication\_group](#input\_create\_global\_replication\_group) | Whether to create a global replication group for multi-region deployment (only applies to primary cluster) | `bool` | `false` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Whether to create a security group for ElastiCache | `bool` | `true` | no |
| <a name="input_data_tiering_enabled"></a> [data\_tiering\_enabled](#input\_data\_tiering\_enabled) | (Optional) Enables data tiering. Data tiering is only supported for replication groups using the r6gd node type | `bool` | `false` | no |
| <a name="input_elasticache_replication_group_id"></a> [elasticache\_replication\_group\_id](#input\_elasticache\_replication\_group\_id) | (Optional) Replication group identifier. This parameter is stored as a lowercase string | `string` | `null` | no |
| <a name="input_elasticache_subnet_group_name"></a> [elasticache\_subnet\_group\_name](#input\_elasticache\_subnet\_group\_name) | (Optional) Name of the cache subnet group. Required if create\_elasticache\_subnet\_group is false | `string` | `null` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | (Optional) Name of the cache engine to be used. Valid values are redis or valkey | `string` | `"redis"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | (Optional) Version number of the cache engine. For version 7+, use major.minor format (e.g., 7.2) | `string` | `"7.0"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/sandbox/prod) | `string` | n/a | yes |
| <a name="input_existing_security_group_ids"></a> [existing\_security\_group\_ids](#input\_existing\_security\_group\_ids) | (Optional) List of existing security group IDs to attach to ElastiCache | `list(string)` | `[]` | no |
| <a name="input_final_snapshot_identifier"></a> [final\_snapshot\_identifier](#input\_final\_snapshot\_identifier) | (Optional) Name of your final node group (shard) snapshot. If omitted, no final snapshot will be made | `string` | `null` | no |
| <a name="input_global_deletion_protection"></a> [global\_deletion\_protection](#input\_global\_deletion\_protection) | Whether deletion protection is enabled for the global replication group | `bool` | `true` | no |
| <a name="input_global_replication_group_id"></a> [global\_replication\_group\_id](#input\_global\_replication\_group\_id) | (Optional) The ID of the global replication group to which this replication group should belong. If not provided, will be auto-generated | `string` | `null` | no |
| <a name="input_ip_discovery"></a> [ip\_discovery](#input\_ip\_discovery) | (Optional) The IP version to advertise in the discovery protocol. Valid values are ipv4 or ipv6 | `string` | `"ipv4"` | no |
| <a name="input_is_secondary_region"></a> [is\_secondary\_region](#input\_is\_secondary\_region) | Whether this is a secondary region in a global replication setup (attaches to existing global replication group) | `bool` | `false` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | (Optional) The ARN of the key that you wish to use if encrypting at rest. Can be specified only if at\_rest\_encryption\_enabled = true | `string` | `null` | no |
| <a name="input_log_delivery_configuration"></a> [log\_delivery\_configuration](#input\_log\_delivery\_configuration) | (Optional, Redis only) Specifies the destination and format of Redis/Valkey SLOWLOG or Engine Log. Max of 2 blocks | <pre>list(object({<br/>    destination      = string<br/>    destination_type = string<br/>    log_format       = string<br/>    log_type         = string<br/>  }))</pre> | `[]` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | (Optional) Specifies the weekly time range for maintenance. Format: ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). Minimum 60 minute period | `string` | `"sun:05:00-sun:06:00"` | no |
| <a name="input_multi_az_enabled"></a> [multi\_az\_enabled](#input\_multi\_az\_enabled) | (Optional) Specifies whether to enable Multi-AZ Support. If true, automatic\_failover\_enabled must also be enabled | `bool` | `true` | no |
| <a name="input_network_type"></a> [network\_type](#input\_network\_type) | (Optional) The IP versions for cache cluster connections. Valid values are ipv4, ipv6, or dual\_stack | `string` | `"ipv4"` | no |
| <a name="input_node_group_configuration"></a> [node\_group\_configuration](#input\_node\_group\_configuration) | (Optional) Configuration for node groups (shards). Can be specified only if num\_node\_groups is set. Conflicts with preferred\_cache\_cluster\_azs | <pre>list(object({<br/>    node_group_id              = optional(string)<br/>    primary_availability_zone  = optional(string)<br/>    primary_outpost_arn        = optional(string)<br/>    replica_availability_zones = optional(list(string))<br/>    replica_count              = optional(number)<br/>    replica_outpost_arns       = optional(list(string))<br/>    slots                      = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | (Optional) Instance class to be used. Required unless global\_replication\_group\_id is set | `string` | `"cache.t3.small"` | no |
| <a name="input_notification_topic_arn"></a> [notification\_topic\_arn](#input\_notification\_topic\_arn) | (Optional) ARN of an SNS topic to send ElastiCache notifications | `string` | `null` | no |
| <a name="input_num_cache_clusters"></a> [num\_cache\_clusters](#input\_num\_cache\_clusters) | (Optional) Number of cache clusters (primary and replicas). Must be at least 2 if automatic\_failover\_enabled or multi\_az\_enabled are true. Conflicts with num\_node\_groups | `number` | `null` | no |
| <a name="input_num_node_groups"></a> [num\_node\_groups](#input\_num\_node\_groups) | (Optional) Number of node groups (shards) for this Redis replication group. Conflicts with num\_cache\_clusters | `number` | `null` | no |
| <a name="input_parameter_group_name"></a> [parameter\_group\_name](#input\_parameter\_group\_name) | (Optional) Name of the parameter group to associate with this replication group | `string` | `"default.redis7"` | no |
| <a name="input_port"></a> [port](#input\_port) | (Optional) Port number on which each cache node will accept connections. Default is 6379 for Redis | `number` | `6379` | no |
| <a name="input_preferred_cache_cluster_azs"></a> [preferred\_cache\_cluster\_azs](#input\_preferred\_cache\_cluster\_azs) | (Optional) List of EC2 availability zones in which the replication group's cache clusters will be created. The first item will be the primary node | `list(string)` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region where this resource will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_replicas_per_node_group"></a> [replicas\_per\_node\_group](#input\_replicas\_per\_node\_group) | (Optional) Number of replica nodes in each node group. Valid values are 0 to 5. Conflicts with num\_cache\_clusters. Can only be set if num\_node\_groups is set | `number` | `null` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | (Optional) Description for the security group. | `string` | `null` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | (Optional) Name of the security group for ElastiCache | `string` | `null` | no |
| <a name="input_snapshot_arn"></a> [snapshot\_arn](#input\_snapshot\_arn) | (Optional) The ARN of a snapshot from which to restore data into the new node group (for cross-region or cross-account restoration) | `string` | `null` | no |
| <a name="input_snapshot_arns"></a> [snapshot\_arns](#input\_snapshot\_arns) | (Optional) List of ARNs that identify Redis RDB snapshot files stored in Amazon S3 | `list(string)` | `null` | no |
| <a name="input_snapshot_name"></a> [snapshot\_name](#input\_snapshot\_name) | (Optional) The name of a snapshot from which to restore data into the new node group | `string` | `null` | no |
| <a name="input_snapshot_retention_limit"></a> [snapshot\_retention\_limit](#input\_snapshot\_retention\_limit) | (Optional, Redis only) Number of days for which ElastiCache will retain automatic snapshots before deleting them. 0 disables backups | `number` | `1` | no |
| <a name="input_snapshot_window"></a> [snapshot\_window](#input\_snapshot\_window) | (Optional, Redis only) Daily time range (in UTC) during which ElastiCache will begin taking a daily snapshot. Minimum 60 minute period | `string` | `"03:00-05:00"` | no |
| <a name="input_source_replication_group_id"></a> [source\_replication\_group\_id](#input\_source\_replication\_group\_id) | ARN of existing replication group to use as primary for global replication group (only used when use\_existing\_as\_global\_primary is true) | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for ElastiCache | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_transit_encryption_enabled"></a> [transit\_encryption\_enabled](#input\_transit\_encryption\_enabled) | (Optional) Whether to enable encryption in transit. Changing this with engine\_version < 7.0.5 will force replacement | `bool` | `false` | no |
| <a name="input_transit_encryption_mode"></a> [transit\_encryption\_mode](#input\_transit\_encryption\_mode) | (Optional) A setting that enables clients to migrate to in-transit encryption with no downtime. Valid values are preferred and required | `string` | `null` | no |
| <a name="input_use_existing_as_global_primary"></a> [use\_existing\_as\_global\_primary](#input\_use\_existing\_as\_global\_primary) | Whether to use existing cluster as primary for global replication group (links existing cluster instead of creating new) | `bool` | `false` | no |
| <a name="input_user_group_ids"></a> [user\_group\_ids](#input\_user\_group\_ids) | (Optional) User Group IDs to associate with the replication group. Maximum of one user group ID | `set(string)` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where resources will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_all_security_group_ids"></a> [all\_security\_group\_ids](#output\_all\_security\_group\_ids) | All security group IDs attached to ElastiCache |
| <a name="output_connection_info"></a> [connection\_info](#output\_connection\_info) | Connection information for the ElastiCache cluster |
| <a name="output_global_replication_group_arn"></a> [global\_replication\_group\_arn](#output\_global\_replication\_group\_arn) | ARN of the Global Replication Group |
| <a name="output_global_replication_group_id"></a> [global\_replication\_group\_id](#output\_global\_replication\_group\_id) | Global Replication Group Identifier |
| <a name="output_global_replication_group_name"></a> [global\_replication\_group\_name](#output\_global\_replication\_group\_name) | Global Replication Group name |
| <a name="output_global_replication_group_suffix"></a> [global\_replication\_group\_suffix](#output\_global\_replication\_group\_suffix) | User-specified suffix for the Global Replication Group (may differ from actual AWS-generated ID) |
| <a name="output_is_primary_cluster"></a> [is\_primary\_cluster](#output\_is\_primary\_cluster) | Whether this cluster is the primary cluster in the global replication group |
| <a name="output_is_secondary_cluster"></a> [is\_secondary\_cluster](#output\_is\_secondary\_cluster) | Whether this cluster is a secondary/replica cluster in the global replication group |
| <a name="output_replication_group_arn"></a> [replication\_group\_arn](#output\_replication\_group\_arn) | ARN of the ElastiCache Replication Group |
| <a name="output_replication_group_configuration_endpoint_address"></a> [replication\_group\_configuration\_endpoint\_address](#output\_replication\_group\_configuration\_endpoint\_address) | Address of the configuration endpoint for the replication group |
| <a name="output_replication_group_id"></a> [replication\_group\_id](#output\_replication\_group\_id) | ID of the ElastiCache Replication Group |
| <a name="output_replication_group_member_clusters"></a> [replication\_group\_member\_clusters](#output\_replication\_group\_member\_clusters) | Identifiers of all member cache clusters |
| <a name="output_replication_group_port"></a> [replication\_group\_port](#output\_replication\_group\_port) | Port number for the replication group |
| <a name="output_replication_group_primary_endpoint_address"></a> [replication\_group\_primary\_endpoint\_address](#output\_replication\_group\_primary\_endpoint\_address) | Address of the primary endpoint for the replication group |
| <a name="output_replication_group_reader_endpoint_address"></a> [replication\_group\_reader\_endpoint\_address](#output\_replication\_group\_reader\_endpoint\_address) | Address of the reader endpoint for the replication group |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the security group created for ElastiCache |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group created for ElastiCache |
| <a name="output_security_group_name"></a> [security\_group\_name](#output\_security\_group\_name) | Name of the security group created for ElastiCache |
| <a name="output_subnet_group_id"></a> [subnet\_group\_id](#output\_subnet\_group\_id) | ID of the ElastiCache subnet group |
| <a name="output_subnet_group_name"></a> [subnet\_group\_name](#output\_subnet\_group\_name) | Name of the ElastiCache subnet group |
<!-- END_TF_DOCS -->