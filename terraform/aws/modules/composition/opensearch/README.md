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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_opensearch"></a> [opensearch](#module\_opensearch) | terraform-aws-modules/opensearch/aws | ~> 2.5 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_service_linked_role.opensearch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_kms_key.default_es](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_advanced_options"></a> [advanced\_options](#input\_advanced\_options) | Key-value string pairs to specify advanced configuration options | `map(string)` | `{}` | no |
| <a name="input_advanced_security_enabled"></a> [advanced\_security\_enabled](#input\_advanced\_security\_enabled) | Whether fine-grained access control is enabled | `bool` | `false` | no |
| <a name="input_anonymous_auth_enabled"></a> [anonymous\_auth\_enabled](#input\_anonymous\_auth\_enabled) | Whether anonymous authentication is enabled | `bool` | `false` | no |
| <a name="input_auto_software_update_enabled"></a> [auto\_software\_update\_enabled](#input\_auto\_software\_update\_enabled) | Whether automatic software updates are enabled | `bool` | `false` | no |
| <a name="input_auto_tune_enabled"></a> [auto\_tune\_enabled](#input\_auto\_tune\_enabled) | Whether Auto-Tune is enabled | `bool` | `true` | no |
| <a name="input_auto_tune_rollback_on_disable"></a> [auto\_tune\_rollback\_on\_disable](#input\_auto\_tune\_rollback\_on\_disable) | Rollback strategy when Auto-Tune is disabled | `string` | `"NO_ROLLBACK"` | no |
| <a name="input_availability_zone_count"></a> [availability\_zone\_count](#input\_availability\_zone\_count) | Number of availability zones for zone awareness (2 or 3) | `number` | `2` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days to retain CloudWatch log events | `number` | `30` | no |
| <a name="input_create_cloudwatch_log_groups"></a> [create\_cloudwatch\_log\_groups](#input\_create\_cloudwatch\_log\_groups) | Whether to create CloudWatch log groups for OpenSearch logs | `bool` | `true` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Whether to create a security group for OpenSearch | `bool` | `true` | no |
| <a name="input_create_service_linked_role"></a> [create\_service\_linked\_role](#input\_create\_service\_linked\_role) | Whether to create the OpenSearch service-linked role | `bool` | `true` | no |
| <a name="input_create_timeout"></a> [create\_timeout](#input\_create\_timeout) | Timeout for creating the OpenSearch domain | `string` | `"60m"` | no |
| <a name="input_custom_endpoint"></a> [custom\_endpoint](#input\_custom\_endpoint) | Custom endpoint domain name | `string` | `null` | no |
| <a name="input_custom_endpoint_certificate_arn"></a> [custom\_endpoint\_certificate\_arn](#input\_custom\_endpoint\_certificate\_arn) | ACM certificate ARN for custom endpoint | `string` | `null` | no |
| <a name="input_custom_endpoint_enabled"></a> [custom\_endpoint\_enabled](#input\_custom\_endpoint\_enabled) | Whether custom endpoint is enabled | `bool` | `false` | no |
| <a name="input_dedicated_master_count"></a> [dedicated\_master\_count](#input\_dedicated\_master\_count) | Number of dedicated master nodes (should be 3 for production) | `number` | `3` | no |
| <a name="input_dedicated_master_enabled"></a> [dedicated\_master\_enabled](#input\_dedicated\_master\_enabled) | Whether dedicated master nodes are enabled | `bool` | `false` | no |
| <a name="input_dedicated_master_type"></a> [dedicated\_master\_type](#input\_dedicated\_master\_type) | Instance type for dedicated master nodes | `string` | `"c6g.large.search"` | no |
| <a name="input_delete_timeout"></a> [delete\_timeout](#input\_delete\_timeout) | Timeout for deleting the OpenSearch domain | `string` | `"60m"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Name of the OpenSearch domain. If not provided, will be generated from environment and project\_name | `string` | `null` | no |
| <a name="input_ebs_enabled"></a> [ebs\_enabled](#input\_ebs\_enabled) | Whether EBS volumes are attached to data nodes | `bool` | `true` | no |
| <a name="input_encrypt_at_rest_enabled"></a> [encrypt\_at\_rest\_enabled](#input\_encrypt\_at\_rest\_enabled) | Whether encryption at rest is enabled | `bool` | `true` | no |
| <a name="input_enforce_https"></a> [enforce\_https](#input\_enforce\_https) | Whether HTTPS is enforced for the domain endpoint | `bool` | `true` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Version of the OpenSearch engine. Format: 'OpenSearch\_X.Y' or 'Elasticsearch\_X.Y' | `string` | `"OpenSearch_2.13"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/sandbox/prod) | `string` | n/a | yes |
| <a name="input_existing_security_group_ids"></a> [existing\_security\_group\_ids](#input\_existing\_security\_group\_ids) | List of existing security group IDs to attach to the OpenSearch domain | `list(string)` | `[]` | no |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | Number of data nodes in the cluster | `number` | `1` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type for the OpenSearch data nodes | `string` | `"r6g.large.search"` | no |
| <a name="input_internal_user_database_enabled"></a> [internal\_user\_database\_enabled](#input\_internal\_user\_database\_enabled) | Whether internal user database is enabled | `bool` | `false` | no |
| <a name="input_ip_address_type"></a> [ip\_address\_type](#input\_ip\_address\_type) | The IP address type for the endpoint. Valid values: ipv4, dualstack | `string` | `"ipv4"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key ID for encryption at rest. If null, uses AWS-managed key | `string` | `null` | no |
| <a name="input_log_types"></a> [log\_types](#input\_log\_types) | List of log types to publish to CloudWatch (ES\_APPLICATION\_LOGS, INDEX\_SLOW\_LOGS, SEARCH\_SLOW\_LOGS, AUDIT\_LOGS) | `list(string)` | <pre>[<br/>  "ES_APPLICATION_LOGS",<br/>  "INDEX_SLOW_LOGS",<br/>  "SEARCH_SLOW_LOGS"<br/>]</pre> | no |
| <a name="input_master_user_arn"></a> [master\_user\_arn](#input\_master\_user\_arn) | ARN of the master user for fine-grained access control | `string` | `null` | no |
| <a name="input_master_user_name"></a> [master\_user\_name](#input\_master\_user\_name) | Username of the master user | `string` | `null` | no |
| <a name="input_master_user_password"></a> [master\_user\_password](#input\_master\_user\_password) | Password of the master user | `string` | `null` | no |
| <a name="input_multi_az_with_standby_enabled"></a> [multi\_az\_with\_standby\_enabled](#input\_multi\_az\_with\_standby\_enabled) | Whether Multi-AZ with standby is enabled | `bool` | `false` | no |
| <a name="input_node_to_node_encryption_enabled"></a> [node\_to\_node\_encryption\_enabled](#input\_node\_to\_node\_encryption\_enabled) | Whether node-to-node encryption is enabled | `bool` | `true` | no |
| <a name="input_off_peak_window_enabled"></a> [off\_peak\_window\_enabled](#input\_off\_peak\_window\_enabled) | Whether off-peak window is enabled for maintenance | `bool` | `true` | no |
| <a name="input_off_peak_window_start_hour"></a> [off\_peak\_window\_start\_hour](#input\_off\_peak\_window\_start\_hour) | Start hour for off-peak window (0-23 UTC) | `number` | `0` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region. Defaults to the region set in the provider configuration | `string` | `null` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | Description of the security group | `string` | `null` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Name of the security group (if create\_security\_group is true) | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the OpenSearch domain | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_tls_security_policy"></a> [tls\_security\_policy](#input\_tls\_security\_policy) | TLS security policy for the domain endpoint | `string` | `"Policy-Min-TLS-1-2-2019-07"` | no |
| <a name="input_update_timeout"></a> [update\_timeout](#input\_update\_timeout) | Timeout for updating the OpenSearch domain | `string` | `"60m"` | no |
| <a name="input_volume_iops"></a> [volume\_iops](#input\_volume\_iops) | Baseline IOPS for EBS volumes (gp3, io1, io2) | `number` | `null` | no |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | Size of EBS volumes in GiB | `number` | `100` | no |
| <a name="input_volume_throughput"></a> [volume\_throughput](#input\_volume\_throughput) | Throughput in MiB/s for gp3 volumes | `number` | `null` | no |
| <a name="input_volume_type"></a> [volume\_type](#input\_volume\_type) | Type of EBS volumes (gp2, gp3, io1, io2) | `string` | `"gp3"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the OpenSearch domain will be created | `string` | n/a | yes |
| <a name="input_warm_count"></a> [warm\_count](#input\_warm\_count) | Number of UltraWarm data nodes | `number` | `null` | no |
| <a name="input_warm_enabled"></a> [warm\_enabled](#input\_warm\_enabled) | Whether UltraWarm data nodes are enabled | `bool` | `false` | no |
| <a name="input_warm_type"></a> [warm\_type](#input\_warm\_type) | Instance type for UltraWarm data nodes | `string` | `null` | no |
| <a name="input_zone_awareness_enabled"></a> [zone\_awareness\_enabled](#input\_zone\_awareness\_enabled) | Whether zone awareness is enabled | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_all_security_group_ids"></a> [all\_security\_group\_ids](#output\_all\_security\_group\_ids) | All security group IDs attached to the OpenSearch domain |
| <a name="output_cloudwatch_log_groups"></a> [cloudwatch\_log\_groups](#output\_cloudwatch\_log\_groups) | Map of CloudWatch log groups created and their attributes |
| <a name="output_connection_info"></a> [connection\_info](#output\_connection\_info) | Connection information for the OpenSearch domain |
| <a name="output_dashboard_endpoint"></a> [dashboard\_endpoint](#output\_dashboard\_endpoint) | Domain-specific endpoint for Dashboard without https scheme |
| <a name="output_dashboard_endpoint_v2"></a> [dashboard\_endpoint\_v2](#output\_dashboard\_endpoint\_v2) | V2 domain endpoint for Dashboard that works with both IPv4 and IPv6 addresses |
| <a name="output_domain_arn"></a> [domain\_arn](#output\_domain\_arn) | The Amazon Resource Name (ARN) of the domain |
| <a name="output_domain_endpoint"></a> [domain\_endpoint](#output\_domain\_endpoint) | Domain-specific endpoint used to submit index, search, and data upload requests |
| <a name="output_domain_endpoint_v2"></a> [domain\_endpoint\_v2](#output\_domain\_endpoint\_v2) | V2 domain endpoint that works with both IPv4 and IPv6 addresses |
| <a name="output_domain_id"></a> [domain\_id](#output\_domain\_id) | The unique identifier for the domain |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | The name of the domain |
| <a name="output_kibana_url"></a> [kibana\_url](#output\_kibana\_url) | Full Kibana/Dashboards URL for the domain |
| <a name="output_kibana_url_legacy"></a> [kibana\_url\_legacy](#output\_kibana\_url\_legacy) | Full Kibana URL for the domain (legacy Elasticsearch) |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | Amazon Resource Name (ARN) of the security group |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group |
| <a name="output_service_linked_role_arn"></a> [service\_linked\_role\_arn](#output\_service\_linked\_role\_arn) | ARN of the OpenSearch service-linked role |
| <a name="output_service_linked_role_name"></a> [service\_linked\_role\_name](#output\_service\_linked\_role\_name) | Name of the OpenSearch service-linked role |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Subnet IDs where the OpenSearch domain is deployed |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID where the OpenSearch domain is deployed |
<!-- END_TF_DOCS -->