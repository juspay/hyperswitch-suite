<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
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
| [aws_elasticache_replication_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |
| [aws_elasticache_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Apply cluster changes immediately rather than during the next maintenance window | `bool` | `true` | no |
| <a name="input_at_rest_encryption_enabled"></a> [at\_rest\_encryption\_enabled](#input\_at\_rest\_encryption\_enabled) | Enable encryption at rest | `bool` | `true` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Valkey engine version | `string` | `"8.2"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment short name (e.g. prd, sbx) | `string` | n/a | yes |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Weekly maintenance window (ddd:hh24:mi-ddd:hh24:mi) | `string` | `"mon:04:00-mon:05:00"` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | ElastiCache node type | `string` | `"cache.t4g.micro"` | no |
| <a name="input_num_cache_clusters"></a> [num\_cache\_clusters](#input\_num\_cache\_clusters) | Number of cache clusters (nodes) in the replication group | `number` | `1` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region (kept for parity with sibling modules; not used by the correlator resources themselves) | `string` | n/a | yes |
| <a name="input_snapshot_retention_limit"></a> [snapshot\_retention\_limit](#input\_snapshot\_retention\_limit) | Number of days to retain automatic snapshots (0 disables backups) | `number` | `7` | no |
| <a name="input_snapshot_window"></a> [snapshot\_window](#input\_snapshot\_window) | Daily snapshot window (hh24:mi-hh24:mi) | `string` | `"23:30-00:30"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the ElastiCache subnet group | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources. Overrides the module's defaults on key conflicts. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the ElastiCache cluster will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_all_security_group_ids"></a> [all\_security\_group\_ids](#output\_all\_security\_group\_ids) | All security group IDs attached to the replication group |
| <a name="output_connection_info"></a> [connection\_info](#output\_connection\_info) | Convenience map with the connection details a client needs |
| <a name="output_is_primary_cluster"></a> [is\_primary\_cluster](#output\_is\_primary\_cluster) | Whether this cluster is the primary cluster in a global replication group (always true — global replication is not supported here) |
| <a name="output_is_secondary_cluster"></a> [is\_secondary\_cluster](#output\_is\_secondary\_cluster) | Whether this cluster is a secondary cluster in a global replication group (always false — global replication is not supported here) |
| <a name="output_replication_group_arn"></a> [replication\_group\_arn](#output\_replication\_group\_arn) | ARN of the Valkey replication group |
| <a name="output_replication_group_configuration_endpoint_address"></a> [replication\_group\_configuration\_endpoint\_address](#output\_replication\_group\_configuration\_endpoint\_address) | Configuration endpoint address (cluster mode only; null when cluster\_mode is disabled) |
| <a name="output_replication_group_id"></a> [replication\_group\_id](#output\_replication\_group\_id) | ID of the Valkey replication group |
| <a name="output_replication_group_member_clusters"></a> [replication\_group\_member\_clusters](#output\_replication\_group\_member\_clusters) | List of member cluster IDs in the replication group |
| <a name="output_replication_group_port"></a> [replication\_group\_port](#output\_replication\_group\_port) | Port the replication group listens on |
| <a name="output_replication_group_primary_endpoint_address"></a> [replication\_group\_primary\_endpoint\_address](#output\_replication\_group\_primary\_endpoint\_address) | Primary endpoint address (used by the correlator service for Redis HOST) |
| <a name="output_replication_group_reader_endpoint_address"></a> [replication\_group\_reader\_endpoint\_address](#output\_replication\_group\_reader\_endpoint\_address) | Reader endpoint address of the replication group |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the security group attached to the Valkey cluster |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group attached to the Valkey cluster (used by security-rules module) |
| <a name="output_security_group_name"></a> [security\_group\_name](#output\_security\_group\_name) | Name of the security group attached to the Valkey cluster |
| <a name="output_subnet_group_id"></a> [subnet\_group\_id](#output\_subnet\_group\_id) | ID of the ElastiCache subnet group |
| <a name="output_subnet_group_name"></a> [subnet\_group\_name](#output\_subnet\_group\_name) | Name of the ElastiCache subnet group |
<!-- END_TF_DOCS -->