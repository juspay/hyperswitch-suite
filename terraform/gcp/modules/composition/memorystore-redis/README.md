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
| <a name="module_redis_cluster"></a> [redis\_cluster](#module\_redis\_cluster) | terraform-google-modules/memorystore/google//modules/redis-cluster | 16.1.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_authorization_mode"></a> [authorization\_mode](#input\_authorization\_mode) | AUTH\_MODE\_DISABLED or AUTH\_MODE\_IAM\_AUTH. No plain-password AUTH option exists on this product (unlike classic Memorystore for Redis's auth\_string) - IAM auth is the only authenticated mode available | `string` | `"AUTH_MODE_DISABLED"` | no |
| <a name="input_cluster_role"></a> [cluster\_role](#input\_cluster\_role) | Cross-cluster replication role: NONE, PRIMARY or SECONDARY. null leaves the cluster standalone. This resource's equivalent of memorystore-valkey's instance\_role (which also allows INSTANCE\_ROLE\_UNSPECIFIED - not a valid value here) | `string` | `null` | no |
| <a name="input_deletion_protection_enabled"></a> [deletion\_protection\_enabled](#input\_deletion\_protection\_enabled) | If true, deletion of the instance fails until this is set false first | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_instance_id"></a> [instance\_id](#input\_instance\_id) | Resource ID of the Redis cluster instance. Defaults to '<environment>-<project\_name>-redis-<region>' | `string` | `null` | no |
| <a name="input_kms_key"></a> [kms\_key](#input\_kms\_key) | CMEK key used to encrypt the cluster's at-rest data. null uses Google-managed encryption. Unlike memorystore-valkey (whose installed submodule version doesn't expose this), this resource forwards it directly | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_network"></a> [network](#input\_network) | Bare name (not self-link/ID) of the VPC network to serve discovery/cluster traffic on - this module builds the full projects/.../global/networks/<name> path itself | `string` | n/a | yes |
| <a name="input_network_project"></a> [network\_project](#input\_network\_project) | Project ID that owns the network, only needed for Shared VPC where the network lives in a different project than project\_id | `string` | `null` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | Redis Cluster node type - four are valid:<br/><br/>  REDIS\_SHARED\_CORE\_NANO<br/>  REDIS\_STANDARD\_SMALL<br/>  REDIS\_HIGHMEM\_MEDIUM<br/>  REDIS\_HIGHMEM\_XLARGE<br/><br/>See https://cloud.google.com/memorystore/docs/cluster/node-specification<br/>for current per-type vCPU/memory figures - not repeated here since they<br/>change independently of this module. Defaults to the cheapest tier<br/>(matching memorystore-valkey's own default convention) rather than the<br/>upstream submodule's default of null, which the API resolves to the much<br/>larger REDIS\_HIGHMEM\_MEDIUM - pass null explicitly to get that instead. | `string` | `"REDIS_SHARED_CORE_NANO"` | no |
| <a name="input_persistence_config"></a> [persistence\_config](#input\_persistence\_config) | In-instance RDB/AOF persistence. There is no automated\_backup\_config pairing on this resource (see the module-level known-gap note above) - this is the only durability knob available. null leaves the API at its default (PERSISTENCE\_MODE\_UNSPECIFIED) | <pre>object({<br/>    mode = optional(string)<br/>    rdb_config = optional(object({<br/>      rdb_snapshot_period     = optional(string)<br/>      rdb_snapshot_start_time = optional(string)<br/>    }), null)<br/>    aof_config = optional(object({<br/>      append_fsync = optional(string)<br/>    }), null)<br/>  })</pre> | `null` | no |
| <a name="input_primary_cluster"></a> [primary\_cluster](#input\_primary\_cluster) | The cluster replicated FROM, set only when cluster\_role = SECONDARY. Format: projects/{project}/locations/{region}/clusters/{cluster-id} | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the instance is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for labeling and naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_redis_configs"></a> [redis\_configs](#input\_redis\_configs) | Engine parameters, set inline rather than as a separate parameter-group resource. Leave null to inherit Memorystore's defaults | <pre>object({<br/>    maxmemory               = optional(string)<br/>    maxmemory-clients       = optional(string)<br/>    maxmemory-policy        = optional(string)<br/>    notify-keyspace-events  = optional(string)<br/>    slowlog-log-slower-than = optional(number)<br/>    maxclients              = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the Redis cluster instance | `string` | n/a | yes |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | Number of replica nodes per shard (0-2 - narrower than Valkey's 0-5 on this resource) | `number` | `0` | no |
| <a name="input_secondary_clusters"></a> [secondary\_clusters](#input\_secondary\_clusters) | Clusters replicating FROM this one, set only when cluster\_role = PRIMARY. Format: projects/{project}/locations/{region}/clusters/{cluster-id} | `list(string)` | `[]` | no |
| <a name="input_shard_count"></a> [shard\_count](#input\_shard\_count) | Number of shards. 1 is a valid, non-sharded 'cluster of one', used for smaller environments | `number` | `1` | no |
| <a name="input_subnet_names"></a> [subnet\_names](#input\_subnet\_names) | Bare names (not self-links) of the subnet(s), in `region`, to reserve Private Service Connect addresses in for cluster discovery. Memorystore for Redis Cluster requires a dedicated PSC-capable subnet - not the Private Service Access path classic Memorystore for Redis uses | `list(string)` | n/a | yes |
| <a name="input_transit_encryption_mode"></a> [transit\_encryption\_mode](#input\_transit\_encryption\_mode) | TRANSIT\_ENCRYPTION\_MODE\_DISABLED or TRANSIT\_ENCRYPTION\_MODE\_SERVER\_AUTHENTICATION | `string` | `"TRANSIT_ENCRYPTION_MODE_DISABLED"` | no |
| <a name="input_weekly_maintenance_window"></a> [weekly\_maintenance\_window](#input\_weekly\_maintenance\_window) | Maintenance window, in UTC. null lets Google pick one. Unlike memorystore-valkey's list(object(...)) (a historical artifact of that submodule's own interface), this resource's underlying submodule takes a single object directly - field names also differ (day\_of\_the\_week/hours/minutes/seconds/nanos here, vs. day\_of\_week/start\_time\_hour/etc. there) | <pre>object({<br/>    day_of_the_week = optional(string)<br/>    hours           = optional(string)<br/>    minutes         = optional(string)<br/>    seconds         = optional(string)<br/>    nanos           = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_zone_distribution_config_mode"></a> [zone\_distribution\_config\_mode](#input\_zone\_distribution\_config\_mode) | Zone distribution for the cluster. MULTI\_ZONE (the default) spreads across zones; SINGLE\_ZONE is only for deliberately cheap non-HA environments. Immutable - changing it on a live instance forces replacement | `string` | `"MULTI_ZONE"` | no |
| <a name="input_zone_distribution_config_zone"></a> [zone\_distribution\_config\_zone](#input\_zone\_distribution\_config\_zone) | The zone for a SINGLE\_ZONE cluster (Immutable). Ignored unless zone\_distribution\_config\_mode is SINGLE\_ZONE. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_discovery_endpoints"></a> [discovery\_endpoints](#output\_discovery\_endpoints) | Full discovery\_endpoints structure for the instance - use this if discovery\_host/discovery\_port aren't sufficient (e.g. more than one network endpoint) |
| <a name="output_discovery_host"></a> [discovery\_host](#output\_discovery\_host) | Discovery endpoint IP address clients connect to for cluster topology discovery |
| <a name="output_discovery_port"></a> [discovery\_port](#output\_discovery\_port) | Port for the discovery endpoint |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | Fully qualified resource ID of the Redis cluster instance |
| <a name="output_psc_connections"></a> [psc\_connections](#output\_psc\_connections) | PSC connections for discovery of the cluster topology and accessing the cluster |
<!-- END_TF_DOCS -->