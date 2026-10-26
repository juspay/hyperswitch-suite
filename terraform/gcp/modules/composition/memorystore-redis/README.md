<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.20 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_redis"></a> [redis](#module\_redis) | terraform-google-modules/memorystore/google | 16.1.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alternative_location_id"></a> [alternative\_location\_id](#input\_alternative\_location\_id) | Zone for the standby (STANDARD\_HA only). Must differ from location\_id, and both must be set together or both left null | `string` | `null` | no |
| <a name="input_auth_enabled"></a> [auth\_enabled](#input\_auth\_enabled) | Enable OSS Redis AUTH. Off by default: the application has no Redis AUTH support | `bool` | `false` | no |
| <a name="input_authorized_network"></a> [authorized\_network](#input\_authorized\_network) | Full resource ID of the VPC the instance is peered into (projects/<project>/global/networks/<name>), e.g. the vpc-network unit's network\_id output. Private Service Access must already be set up on it (an allocated range plus the service networking connection), which vpc-network does | `string` | n/a | yes |
| <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key) | CMEK key for at-rest encryption. null uses Google-managed encryption | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_instance_id"></a> [instance\_id](#input\_instance\_id) | Instance ID. Defaults to '<environment>-<project\_name>-redis-<region>'. Classic Memorystore allows 1-40 characters: lowercase letters, digits and hyphens, starting with a letter | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to the instance | `map(string)` | `{}` | no |
| <a name="input_location_id"></a> [location\_id](#input\_location\_id) | Zone for the primary. null lets Google choose. When set together with alternative\_location\_id, both nodes are pinned | `string` | `null` | no |
| <a name="input_maintenance_policy"></a> [maintenance\_policy](#input\_maintenance\_policy) | Weekly maintenance window, in UTC. null lets Google pick one | <pre>object({<br/>    description = optional(string)<br/>    day         = string<br/>    start_time = object({<br/>      hours   = number<br/>      minutes = number<br/>      seconds = number<br/>      nanos   = number<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_memory_size_gb"></a> [memory\_size\_gb](#input\_memory\_size\_gb) | Capacity in GiB (1-300). The capacity tier - and with it network throughput - grows with size (M1 1-4, M2 5-10, M3 11-35 ...), so a larger instance is also a faster one. See https://cloud.google.com/memorystore/docs/redis/instance-tiers-and-sizes | `number` | `1` | no |
| <a name="input_persistence_config"></a> [persistence\_config](#input\_persistence\_config) | In-instance persistence: { persistence\_mode = "RDB", rdb\_snapshot\_period = "ONE\_HOUR" \| "SIX\_HOURS" \| "TWELVE\_HOURS" \| "TWENTY\_FOUR\_HOURS" }. null leaves persistence off | <pre>object({<br/>    persistence_mode    = string<br/>    rdb_snapshot_period = string<br/>  })</pre> | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the instance is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for labeling and naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_read_replica_count"></a> [read\_replica\_count](#input\_read\_replica\_count) | Readable replicas ON TOP of the HA standby, 0-5 (STANDARD\_HA only). 0 leaves read replicas disabled. Enabling them on an existing instance needs secondary\_ip\_range, and the standby itself is not readable. NOT the cluster product's per-shard replica\_count - that variable no longer exists here | `number` | `0` | no |
| <a name="input_redis_configs"></a> [redis\_configs](#input\_redis\_configs) | Redis parameters, e.g. { maxmemory-policy = "volatile-lru" }. Leave empty to inherit Memorystore's defaults | `map(string)` | `{}` | no |
| <a name="input_redis_version"></a> [redis\_version](#input\_redis\_version) | Redis version, e.g. REDIS\_6\_X, REDIS\_7\_0, REDIS\_7\_2. Pinned by default (the registry module's own default is null, which tracks Google's current default and can drift) | `string` | `"REDIS_7_2"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the Redis instance | `string` | n/a | yes |
| <a name="input_reserved_ip_range"></a> [reserved\_ip\_range](#input\_reserved\_ip\_range) | NAME of an allocated Private Service Access range to place the instance in (the vpc-network unit's private\_service\_access\_range\_name output). null lets the service pick an unused /29 from any allocated range | `string` | `null` | no |
| <a name="input_secondary_ip_range"></a> [secondary\_ip\_range](#input\_secondary\_ip\_range) | Extra /28 range for read-replica node placement. Required only when turning read replicas on for an existing instance | `string` | `null` | no |
| <a name="input_tier"></a> [tier](#input\_tier) | STANDARD\_HA (primary + standby in another zone, automatic and manual failover) or BASIC (single node, no failover - cheapest, for throwaway environments only) | `string` | `"STANDARD_HA"` | no |
| <a name="input_transit_encryption_mode"></a> [transit\_encryption\_mode](#input\_transit\_encryption\_mode) | DISABLED or SERVER\_AUTHENTICATION (TLS). DISABLED by default - the registry module defaults to TLS on, but the application connects in plaintext inside the VPC. Immutable after creation | `string` | `"DISABLED"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_auth_string"></a> [auth\_string](#output\_auth\_string) | AUTH password, only when auth\_enabled = true |
| <a name="output_current_location_id"></a> [current\_location\_id](#output\_current\_location\_id) | The zone the primary currently runs in. Changes after a failover |
| <a name="output_host"></a> [host](#output\_host) | IP address of the primary endpoint. A plain (non-cluster) Redis endpoint: clients connect here directly, there is no discovery step. After a failover this address does not change |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | Fully qualified resource ID of the Redis instance (projects/<project>/locations/<region>/instances/<name>) |
| <a name="output_port"></a> [port](#output\_port) | Port of the primary endpoint |
| <a name="output_read_endpoint"></a> [read\_endpoint](#output\_read\_endpoint) | IP address of the read-only endpoint, populated only when read replicas are enabled (read\_replica\_count > 0) |
<!-- END_TF_DOCS -->