<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_memorystore"></a> [memorystore](#module\_memorystore) | terraform-google-modules/memorystore/google | 16.1.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auth_enabled"></a> [auth\_enabled](#input\_auth\_enabled) | Whether to enable Redis AUTH | `bool` | `true` | no |
| <a name="input_authorized_network"></a> [authorized\_network](#input\_authorized\_network) | Self-link/ID of the VPC network the instance is peered to (requires Private Service Access, see composition/vpc-network) | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Name of the Redis instance. Defaults to '<environment>-<project\_name>-redis-<region>' | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_memory_size_gb"></a> [memory\_size\_gb](#input\_memory\_size\_gb) | Redis memory size in GB | `number` | `5` | no |
| <a name="input_persistence_mode"></a> [persistence\_mode](#input\_persistence\_mode) | Persistence mode: RDB or DISABLED. Null leaves persistence unmanaged by this module | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the instance is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for labeling and naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_rdb_snapshot_period"></a> [rdb\_snapshot\_period](#input\_rdb\_snapshot\_period) | RDB snapshot period, required when persistence\_mode is RDB | `string` | `"TWENTY_FOUR_HOURS"` | no |
| <a name="input_redis_configs"></a> [redis\_configs](#input\_redis\_configs) | Map of Redis configuration parameters (e.g. maxmemory-policy) | `map(any)` | `{}` | no |
| <a name="input_redis_version"></a> [redis\_version](#input\_redis\_version) | Redis version | `string` | `"REDIS_7_2"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the Memorystore instance | `string` | n/a | yes |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | Number of read replicas (0 disables read replicas). Only supported on STANDARD\_HA | `number` | `0` | no |
| <a name="input_tier"></a> [tier](#input\_tier) | Service tier: BASIC or STANDARD\_HA (STANDARD\_HA is the closest match to the AWS module's replication-group default) | `string` | `"STANDARD_HA"` | no |
| <a name="input_transit_encryption_mode"></a> [transit\_encryption\_mode](#input\_transit\_encryption\_mode) | Transit encryption mode: SERVER\_AUTHENTICATION or DISABLED | `string` | `"SERVER_AUTHENTICATION"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_auth_string"></a> [auth\_string](#output\_auth\_string) | AUTH string for the instance, if auth\_enabled is true |
| <a name="output_host"></a> [host](#output\_host) | Primary endpoint hostname/IP of the instance |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | Fully qualified ID of the Memorystore instance |
| <a name="output_port"></a> [port](#output\_port) | Port the instance listens on |
| <a name="output_read_endpoint"></a> [read\_endpoint](#output\_read\_endpoint) | Read endpoint (host/port), populated only when read replicas are enabled |
<!-- END_TF_DOCS -->
