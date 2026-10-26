# Dev stack

Full single-region composition of the catalog for the internal environments.
Start with `dev`; the same unit layout is promoted to `pre-prod` and `prod`
with larger sizing and real domains. This stack creates its own VPC and wires
up every catalog unit.

Rendered by `terraform/aws/live/terragrunt.stack.hcl` — one `stack` block per
environment — into `terraform/aws/live/<env>/<region>/`.

## Units and phases

| Phase | Units | `path` |
|---|---|---|
| 1. Network & DNS | `vpc-network`, `route53`, `acm` | `vpc-network`, `route53`, `acm` |
| 2. Data layer | `database`, `elasticache`, `efs`, `kafka`, `locker` | same |
| 3. Proxies & access | `squid-proxy`, `envoy-proxy`, `jump-host` | same |
| 4. Compute | `eks-01` | `application-stack/eks-01` |
| 5. K8s resources | `eks-resources`, `utils-load-balancer` | `application-stack/eks-resources`, `application-stack/utils-load-balancer` |
| 6. Apps | `alb-controller`, `external-secrets`, `istio`, `otel`, `vector-dr`, `loki`, `grafana`, `ratelimiter`, `hyperswitch`, `decision-engine`, `superposition` | `application-stack/apps/<name>` |
| 7. Security rules | `security-rules` (apply last) | `security-rules` |

26 units total. `hyperswitch` must land before `decision-engine` and
`superposition` — both depend on its KMS key output.

**The `path` values above are load-bearing.** Every unit's
`dependency { config_path = "../..." }` (e.g. `apps/istio`'s
`config_path = "../../eks-01"`, `eks-resources`' `config_path = "../../efs"`)
is written against this exact layout. Do not rename a unit's `path` here
without updating every other unit's `config_path` that points at it.

## VPC mode

No unit in this stack is passed `vpc_id` / `*_subnet_ids`. Every VPC-consuming
unit's `dependency "vpc" { enabled = try(values.vpc_id, null) == null }` toggle
therefore resolves to `true`, and the unit reads its networking inputs from the
`vpc-network` unit created here instead. See `units/database/terragrunt.hcl`
for the canonical form of this pattern.

## Required values

These come from `terraform/aws/live/terragrunt.stack.hcl` and hard-fail the
relevant unit if missing (as opposed to `try(values.X, default)` fields, which
are optional):

| Value | Consumed by |
|---|---|
| `vpc_cidr_prefix` | `vpc-network` |
| `base_domain` | `route53`, `acm`, `envoy-proxy` (SES fallback), `grafana`, `superposition` |
| `ami_id` | `locker`, `squid-proxy`, `envoy-proxy`, `jump-host` |
| `virtual_hosts_domains` | `envoy-proxy` — a map of lists, e.g. `{ api = ["api.dev.example.com"] }` |
| `istio_host_domains` | `istio` — passed through as the unit's `host_domains` |
| `admin_role_arn` | `eks-01` (becomes `admin_sso_role_arn`) |
| `admin_access_cidrs` | `eks-01` (public endpoint access list; pass `[]` if unused) |
| `eks_instance_types` | `eks-01` (`system_nodes` and `generic_compute` node groups) |

## Optional values

All of these fall back to unit defaults if omitted from
`terraform/aws/live/terragrunt.stack.hcl`. Shared/common keys are listed first;
per-unit keys are grouped by unit below.

### Shared sizing / operational keys

| Value | Default | Consumed by |
|---|---|---|
| `system_nodes_desired_size` | `1` | `eks-01` |
| `system_nodes_min_size` | `1` | `eks-01` |
| `system_nodes_max_size` | `50` | `eks-01` |
| `generic_compute_desired_size` | `2` | `eks-01` |
| `generic_compute_min_size` | `1` | `eks-01` |
| `generic_compute_max_size` | `50` | `eks-01` |
| `db_instance_class` | `"db.r5.large"` | `database` |
| `db_engine_version` | `"17.9"` | `database` (legacy shared key) |
| `db_backup_retention_period` | `7` | `database` |
| `cache_node_type` | `"cache.m6g.large"` | `elasticache` |
| `cache_num_node_groups` | `2` | `elasticache` |
| `cache_replicas_per_node_group` | `1` | `elasticache` |
| `cache_node_group_configuration` | 2 shards | `elasticache` |
| `cluster_autoscaler_image` | unit default | `eks-resources` |
| `cluster_autoscaler_image_version` | `"v1.35.0"` | `eks-resources` |
| `cluster_autoscaler_requests_cpu` | `"100m"` | `eks-resources` |
| `cluster_autoscaler_requests_memory` | `"600Mi"` | `eks-resources` |
| `cluster_autoscaler_limits_cpu` | `"100m"` | `eks-resources` |
| `cluster_autoscaler_limits_memory` | `"600Mi"` | `eks-resources` |
| `cluster_autoscaler_log_level` | `4` | `eks-resources` |
| `cluster_autoscaler_expander` | `"least-waste"` | `eks-resources` |
| `cluster_autoscaler_skip_local_storage` | `false` | `eks-resources` |
| `cluster_autoscaler_skip_system_pods` | `false` | `eks-resources` |
| `cluster_autoscaler_service_account_name` | unit default | `eks-resources` |

### Whole-object overrides

These keys accept a complete object and override the defaults or the flat sizing keys above:

| Value | Consumed by |
|---|---|
| `eks_01_addon_versions` | `eks-01` — map of EKS addon names to versions |
| `eks_01_system_nodes` | `eks-01` — full node-group object |
| `eks_01_generic_compute` | `eks-01` — full node-group object |
| `eks_01_monitoring` | `eks-01` — full node-group object (creates monitoring node group) |
| `eks_01_keymanager` | `eks-01` — full node-group object (creates keymanager node group) |
| `eks_01_auxillary` | `eks-01` — full node-group object (creates auxillary node group) |

### `vpc-network`

| Value | Default |
|---|---|
| `single_nat_gateway` | `false` |
| `custom_interface_vpc_endpoints` | unit default |

### `route53`

| Value | Default |
|---|---|
| `public_zone_records` | `{}` |
| `internal_zone_records` | `{}` |

### `database`

| Value | Default |
|---|---|
| `database_engine_version` | `"17.9"` |
| `database_storage_type` | `"aurora-iopt1"` |
| `database_backup_window` | `"00:51-01:21"` |
| `database_maintenance_window` | `"thu:00:12-thu:00:42"` |
| `database_performance_insights_retention_period` | `7` |
| `database_cluster_identifier` | unit default |
| `database_cluster_instance_identifier` | unit default |

### `elasticache`

| Value | Default |
|---|---|
| `elasticache_engine_version` | `"8.2"` |
| `elasticache_snapshot_retention_limit` | `7` |
| `elasticache_snapshot_window` | `"23:30-00:30"` |
| `elasticache_maintenance_window` | `"mon:04:00-mon:05:00"` |

### `efs`

| Value | Default |
|---|---|
| `efs_performance_mode` | `"generalPurpose"` |
| `efs_throughput_mode` | `"elastic"` |
| `efs_lifecycle_transition_to_ia` | `"AFTER_30_DAYS"` |
| `efs_lifecycle_transition_to_primary_storage_class` | `"AFTER_1_ACCESS"` |

### `kafka`

| Value | Default |
|---|---|
| `kafka_broker_count` | `3` |
| `kafka_broker_instance_type` | `"t4g.medium"` |
| `kafka_broker_data_volume_size` | `30` |
| `kafka_broker_data_volume_type` | `"gp3"` |
| `kafka_broker_root_volume_size` | `30` |
| `kafka_broker_root_volume_type` | `"gp3"` |
| `kafka_controller_instance_type` | `"t4g.medium"` |
| `kafka_controller_metadata_volume_size` | `10` |
| `kafka_controller_metadata_volume_type` | `"gp3"` |
| `kafka_controller_root_volume_size` | `30` |
| `kafka_controller_root_volume_type` | `"gp3"` |
| `kafka_broker_ami_id` | unit default |
| `kafka_controller_ami_id` | unit default |

### `locker`

| Value | Default |
|---|---|
| `locker_instance_type` | `"t3.medium"` |
| `locker_db_instance_class` | `"db.r6g.large"` |
| `locker_backup_retention_period` | `7` |
| `locker_storage_type` | `"aurora-iopt1"` |
| `locker_log_retention_days` | `30` |
| `locker_backup_window` | `"02:03-02:33"` |
| `locker_maintenance_window` | `"tue:00:25-tue:00:55"` |

### `squid-proxy`

| Value | Default |
|---|---|
| `squid_instance_type` | `"t3.medium"` |
| `squid_min_size` / `squid_max_size` / `squid_desired_capacity` | `1` / `6` / `1` |
| `squid_root_volume_size` | `30` |
| `squid_root_volume_type` | `"gp3"` |
| `squid_port` | `3128` |
| `squid_generate_ssh_key` | `true` |
| `squid_cpu_scaling_target_value` | `70.0` |
| `squid_memory_scaling_target_value` | `70.0` |
| `squid_instance_refresh_min_healthy_percentage` | `50` |
| `squid_instance_refresh_max_healthy_percentage` | `150` |
| `squid_instance_refresh_warmup` | `60` |
| `squid_instance_refresh_checkpoint_delay` | `300` |

### `envoy-proxy`

| Value | Default |
|---|---|
| `envoy_instance_type` | `"t3.medium"` |
| `envoy_min_size` / `envoy_max_size` / `envoy_desired_capacity` | `1` / `10` / `1` |
| `envoy_root_volume_size` | `20` |
| `envoy_root_volume_type` | `"gp3"` |
| `envoy_cpu_scaling_target_value` | `70.0` |
| `envoy_memory_scaling_target_value` | `70.0` |
| `envoy_health_check_interval` | `30` |
| `envoy_health_check_timeout` | `10` |
| `envoy_health_check_healthy_threshold` | `2` |
| `envoy_health_check_unhealthy_threshold` | `2` |
| `envoy_target_group_deregistration_delay` | `30` |
| `envoy_enable_spot_instances` | `false` |
| `envoy_spot_instance_percentage` | `50` |
| `envoy_on_demand_base_capacity` | `1` |
| `envoy_spot_allocation_strategy` | `"capacity-optimized"` |
| `envoy_enable_capacity_rebalance` | `false` |
| `envoy_max_instance_lifetime` | `0` |
| `envoy_generate_ssh_key` | `true` |

### `jump-host`

| Value | Default |
|---|---|
| `jump_host_instance_type` | `"t3.medium"` |
| `jump_host_root_volume_size` | `30` |
| `jump_host_root_volume_type` | `"gp3"` |
| `jump_host_log_retention_days` | `30` |
| `jump_host_create_ssm_session_preferences` | `true` |
| `jump_host_ssm_idle_session_timeout` | `10` |
| `jump_host_ssm_max_session_duration` | `""` |
| `jump_host_ssm_run_as_user` | `"ubuntu"` |
| `jump_host_ssm_cloudwatch_logging_enabled` | `false` |
| `jump_host_ssm_cloudwatch_log_group_retention_days` | `90` |
| `jump_host_ssm_s3_logging_enabled` | `false` |
| `jump_host_ssm_s3_bucket_lifecycle_days` | `90` |

### `eks-01`

| Value | Default |
|---|---|
| `eks_version` | `"1.35"` |
| `eks_ami_id` | unit default |
| `eks_default_node_os` | `"al2023"` |
| `eks_root_volume_size` | `20` |
| `eks_root_volume_type` | `"gp3"` |

### `eks-resources`

| Value | Default |
|---|---|
| `eks_resources_efs_storage_class_base_path` | `"/superposition/backup-config"` |
| `eks_resources_efs_storage_class_directory_perms` | `"700"` |

### `utils-load-balancer`

| Value | Default |
|---|---|
| `utils_load_balancer_create_alb` | `false` |

### Application namespaces and service accounts

| Value | Default | Consumed by |
|---|---|---|
| `alb_controller_namespace` | `"kube-system"` | `alb-controller` |
| `alb_controller_service_account_name` | `"aws-load-balancer-controller-sa"` | `alb-controller` |
| `external_secrets_namespace` | `"external-secrets-operator"` | `external-secrets` |
| `external_secrets_service_account_name` | `"external-secrets-sa"` | `external-secrets` |
| `istio_namespace` | `"istio-system"` | `istio` |
| `otel_namespace` | `"monitoring"` | `otel` |
| `otel_service_account_name` | `"otel-collector"` | `otel` |
| `vector_dr_namespace` | `"vector"` | `vector-dr` |
| `vector_dr_service_account_name` | `"vector-dr"` | `vector-dr` |
| `loki_namespace` | `"loki"` | `loki` |
| `loki_service_account_name` | `"loki"` | `loki` |
| `grafana_namespace` | `"monitoring"` | `grafana` |
| `grafana_service_account_name` | `"grafana"` | `grafana` |
| `ratelimiter_namespace` | `"ratelimiter"` | `ratelimiter` |
| `ratelimiter_service_account_name` | `"ratelimiter-sa"` | `ratelimiter` |
| `hyperswitch_namespace` | `"hyperswitch"` | `hyperswitch` |
| `hyperswitch_service_account_name` | `"hyperswitch-router-role"` | `hyperswitch` |
| `decision_engine_namespace` | `"decision-engine"` | `decision-engine` |
| `decision_engine_service_account_name` | `"decision-engine-sa"` | `decision-engine` |
| `superposition_namespace` | `"superposition"` | `superposition` |
| `superposition_service_account_name` | `"superposition-role"` | `superposition` |

### Application-specific tunables

| Value | Default | Consumed by |
|---|---|---|
| `alb_controller_create_service_account` | `false` | `alb-controller` |
| `alb_controller_create_helm_release` | `false` | `alb-controller` |
| `istio_create_helm_releases` | `false` | `istio` |
| `grafana_database_engine_version` | `"16.11"` | `grafana` |
| `grafana_db_instance_class` | `"db.t4g.medium"` | `grafana` |
| `grafana_database_backup_retention_period` | `7` | `grafana` |
| `grafana_database_deletion_protection` | `false` | `grafana` |
| `grafana_database_apply_immediately` | `true` | `grafana` |
| `grafana_database_skip_final_snapshot` | `true` | `grafana` |
| `ratelimiter_cache_engine_version` | `"8.2"` | `ratelimiter` |
| `ratelimiter_cache_parameter_group_name` | `"default.valkey8"` | `ratelimiter` |
| `ratelimiter_cache_num_clusters` | `2` | `ratelimiter` |
| `ratelimiter_cache_maintenance_window` | `"sun:05:00-sun:06:00"` | `ratelimiter` |
| `ratelimiter_cache_snapshot_window` | `"03:00-05:00"` | `ratelimiter` |
| `ratelimiter_cache_snapshot_retention_limit` | `1` | `ratelimiter` |
| `ratelimiter_cache_apply_immediately` | `false` | `ratelimiter` |
| `hyperswitch_s3_dashboard_themes_versioning_enabled` | `true` | `hyperswitch` |
| `hyperswitch_s3_dashboard_themes_force_destroy` | `false` | `hyperswitch` |
| `hyperswitch_s3_file_uploads_versioning_enabled` | `true` | `hyperswitch` |
| `hyperswitch_s3_file_uploads_force_destroy` | `false` | `hyperswitch` |
| `decision_engine_s3_force_destroy` | `false` | `decision-engine` |
| `decision_engine_s3_versioning_enabled` | `true` | `decision-engine` |
| `decision_engine_s3_noncurrent_version_expiration_days` | `30` | `decision-engine` |
| `vector_dr_s3_force_destroy` | `true` | `vector-dr` |
| `vector_dr_s3_versioning_enabled` | `false` | `vector-dr` |
| `vector_dr_sqs_message_retention` | `1209600` | `vector-dr` |
| `vector_dr_sqs_receive_wait_time` | `20` | `vector-dr` |
| `vector_dr_sqs_visibility_timeout` | `300` | `vector-dr` |
| `loki_s3_force_destroy` | `false` | `loki` |
| `loki_s3_versioning_enabled` | `false` | `loki` |
| `loki_s3_lifecycle_expiration_days` | `365` | `loki` |
| `superposition_engine_version` | `"17.9"` | `superposition` |
| `superposition_db_cluster_parameter_group_name` | `"default.aurora-postgresql17"` | `superposition` |
| `superposition_db_parameter_group_name` | `"default.aurora-postgresql17"` | `superposition` |
| `superposition_db_instance_class` | `"db.r6g.large"` | `superposition` |
| `superposition_backup_retention_period` | `7` | `superposition` |
| `superposition_skip_final_snapshot` | `true` | `superposition` |
| `superposition_deletion_protection` | `true` | `superposition` |
| `superposition_apply_immediately` | `true` | `superposition` |

`terraform/aws/live/terragrunt.stack.hcl` currently fills the required values
with `REPLACE_ME`-style placeholders per environment — `terragrunt stack generate`
succeeds, but `terragrunt run-all plan` will not until real values are filled
in.

## Prerequisites

- An existing, versioned + encrypted S3 bucket per environment for
  `values.state_bucket` (`remote_state.disable_bucket_update = true` — this
  stack does not create or modify the bucket).
- Terragrunt >= 1.1.

## Workflow

```bash
cd terraform/aws/live
terragrunt stack generate       # renders the unit tree into <env>/<region>/
git add . && git commit          # the generated tree is committed

cd dev/eu-central-1
terragrunt run-all apply         # applies units in dependency order
```
