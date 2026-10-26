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
| <a name="module_valkey_cluster"></a> [valkey\_cluster](#module\_valkey\_cluster) | terraform-google-modules/memorystore/google//modules/valkey | 16.1.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_authorization_mode"></a> [authorization\_mode](#input\_authorization\_mode) | AUTH\_DISABLED or IAM\_AUTH. No plain-password AUTH option exists on this product (unlike classic Memorystore for Redis's auth\_string) - IAM\_AUTH is the only authenticated mode available | `string` | `"AUTH_DISABLED"` | no |
| <a name="input_automated_backup_config"></a> [automated\_backup\_config](#input\_automated\_backup\_config) | Scheduled off-instance backups. null means no automated backups, which is the API default. retention is a duration string (e.g. "604800s" for 7 days); start\_time is the UTC hour | <pre>object({<br/>    start_time = string<br/>    retention  = string<br/>  })</pre> | `null` | no |
| <a name="input_deletion_protection_enabled"></a> [deletion\_protection\_enabled](#input\_deletion\_protection\_enabled) | If true, deletion of the instance fails until this is set false first | `bool` | `true` | no |
| <a name="input_engine_configs"></a> [engine\_configs](#input\_engine\_configs) | Engine parameters, set inline rather than as a separate parameter-group resource. Leave null to inherit Memorystore's defaults | <pre>object({<br/>    maxmemory               = optional(string)<br/>    maxmemory-clients       = optional(string)<br/>    maxmemory-policy        = optional(string)<br/>    notify-keyspace-events  = optional(string)<br/>    slowlog-log-slower-than = optional(number)<br/>    maxclients              = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Valkey engine version | `string` | `"VALKEY_8_0"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_gcs_source"></a> [gcs\_source](#input\_gcs\_source) | Restore the new instance from RDB file(s) in GCS - comma-separated gs:// URIs, and the practical path for a data migration. Only honoured at create time | `string` | `null` | no |
| <a name="input_instance_id"></a> [instance\_id](#input\_instance\_id) | Resource ID of the Valkey cluster instance. Defaults to '<environment>-<project\_name>-valkey-<region>' | `string` | `null` | no |
| <a name="input_instance_role"></a> [instance\_role](#input\_instance\_role) | Cross-region replication role: PRIMARY, SECONDARY, NONE or INSTANCE\_ROLE\_UNSPECIFIED. null leaves the instance standalone | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_maintenance_version"></a> [maintenance\_version](#input\_maintenance\_version) | Desired maintenance version, used to trigger a self-service update. An explicit opt-in per upgrade rather than a standing policy. Upgrade-only - downgrades are not supported | `string` | `null` | no |
| <a name="input_managed_backup_source"></a> [managed\_backup\_source](#input\_managed\_backup\_source) | Restore the new instance from an existing Memorystore backup. Format: projects/{project}/locations/{location}/backupCollections/{collection}/backups/{backup}. Only honoured at create time | `string` | `null` | no |
| <a name="input_mode"></a> [mode](#input\_mode) | CLUSTER or CLUSTER\_DISABLED. Even a single-shard instance should normally use CLUSTER - that's the cluster-protocol-speaking product this module wraps | `string` | `"CLUSTER"` | no |
| <a name="input_network"></a> [network](#input\_network) | Bare name (not self-link/ID) of the VPC network to serve discovery/cluster traffic on - the underlying registry module builds the full projects/.../global/networks/<name> path itself | `string` | n/a | yes |
| <a name="input_network_project"></a> [network\_project](#input\_network\_project) | Project ID that owns the network, only needed for Shared VPC where the network lives in a different project than project\_id | `string` | `null` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | Valkey cluster node type; nine are valid. Compare on WRITABLE keyspace rather<br/>than the headline size, since Memorystore reserves overhead per node:<br/><br/>  SHARED\_CORE\_NANO  1.12 GB writable / 1.4 GB    ~ cache.t4g.micro<br/>  custom-pico       1.08 GB / 1.25 GB<br/>  custom-micro      2 GB    / 2.5 GB             ~ cache.t4g.small band<br/>  custom-mini       3 GB    / 3.75 GB<br/>  STANDARD\_SMALL    5.2 GB  / 6.5 GB             ~ cache.m6g.large (6.38 GiB)<br/>  HIGHMEM\_MEDIUM    10.4 GB / 13 GB              ~ cache.m6g.xlarge<br/>  highcpu-medium    10.4 GB / 13 GB<br/>  standard-large    20.8 GB / 26 GB              ~ cache.m6g.2xlarge<br/>  HIGHMEM\_XLARGE    46.4 GB / 58 GB              ~ cache.r6g.2xlarge<br/>  highmem-2xlarge   88 GB   / 110 GB             ~ cache.r6g.4xlarge<br/><br/>STANDARD\_SMALL is the row that matters when promoting the AWS prod topology<br/>(cache.m6g.large) to GCP. | `string` | `"SHARED_CORE_NANO"` | no |
| <a name="input_persistence_config"></a> [persistence\_config](#input\_persistence\_config) | In-instance RDB/AOF persistence, paired with automated\_backup\_config for off-instance backups. Upstream's default of {} leaves the API at DISABLED | <pre>object({<br/>    mode = optional(string)<br/>    rdb_config = optional(object({<br/>      rdb_snapshot_period     = optional(string)<br/>      rdb_snapshot_start_time = optional(string)<br/>    }), null)<br/>    aof_config = optional(object({<br/>      append_fsync = string<br/>    }), null)<br/>  })</pre> | `{}` | no |
| <a name="input_primary_instance"></a> [primary\_instance](#input\_primary\_instance) | The instance replicated FROM, set only when instance\_role = SECONDARY. Format: projects/{project}/locations/{region}/instances/{instance-id} | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the instance is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for labeling and naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the Valkey cluster instance | `string` | n/a | yes |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | Number of replica nodes per shard (0-5) | `number` | `1` | no |
| <a name="input_secondary_instance"></a> [secondary\_instance](#input\_secondary\_instance) | Instances replicating FROM this one, set only when instance\_role = PRIMARY. Format: projects/{project}/locations/{region}/instances/{instance-id}. | `list(string)` | `[]` | no |
| <a name="input_shard_count"></a> [shard\_count](#input\_shard\_count) | Number of shards. 1 is a valid, non-sharded 'cluster of one', used for smaller environments | `number` | `1` | no |
| <a name="input_subnet_names"></a> [subnet\_names](#input\_subnet\_names) | Bare names (not self-links) of the subnet(s), in `region`, to reserve Private Service Connect addresses in for cluster discovery. Memorystore for Valkey requires a dedicated PSC-capable subnet - not the Private Service Access path classic Memorystore for Redis uses | `list(string)` | n/a | yes |
| <a name="input_transit_encryption_mode"></a> [transit\_encryption\_mode](#input\_transit\_encryption\_mode) | TRANSIT\_ENCRYPTION\_DISABLED or SERVER\_AUTHENTICATION | `string` | `"TRANSIT_ENCRYPTION_DISABLED"` | no |
| <a name="input_weekly_maintenance_window"></a> [weekly\_maintenance\_window](#input\_weekly\_maintenance\_window) | Maintenance window, in UTC. null lets Google pick one. At most one window is supported | <pre>list(object({<br/>    day_of_week        = string<br/>    start_time_hour    = optional(string)<br/>    start_time_minutes = optional(string)<br/>    start_time_seconds = optional(string)<br/>    start_time_nanos   = optional(string)<br/>  }))</pre> | `null` | no |
| <a name="input_zone_distribution_config_mode"></a> [zone\_distribution\_config\_mode](#input\_zone\_distribution\_config\_mode) | Zone distribution for the cluster. MULTI\_ZONE (the default) spreads across zones; SINGLE\_ZONE is only for deliberately cheap non-HA environments. Immutable - changing it on a live instance forces replacement | `string` | `"MULTI_ZONE"` | no |
| <a name="input_zone_distribution_config_zone"></a> [zone\_distribution\_config\_zone](#input\_zone\_distribution\_config\_zone) | The zone for a SINGLE\_ZONE cluster (Immutable). Ignored unless zone\_distribution\_config\_mode is SINGLE\_ZONE. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_discovery_host"></a> [discovery\_host](#output\_discovery\_host) | Discovery endpoint IP address clients connect to for cluster topology discovery. Derived from local.discovery\_connection rather than the submodule's psc\_auto\_connection output - see locals.tf |
| <a name="output_discovery_port"></a> [discovery\_port](#output\_discovery\_port) | Port for the discovery endpoint |
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Full endpoints structure for the instance (all connections, all endpoint types) - use this if discovery\_host/discovery\_port aren't sufficient |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | Fully qualified resource ID of the Valkey cluster instance |
<!-- END_TF_DOCS -->