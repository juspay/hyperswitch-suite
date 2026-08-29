# ElastiCache Redis/Valkey Stress Test Module

Generic Terraform module that deploys Lambda-based stress tests for Amazon ElastiCache Redis or Valkey.

## What it creates

- IAM role for Lambda with VPC, CloudWatch, and optional ElastiCache failover access
- Optional Lambda security group (or reuse an existing one)
- `cpu_stress` — phased Lua CPU burn (or flat mode)
- `mixed_workload` — open-loop mixed command workload (GET/SET/HGET/HSET/INCR) with latency percentile tracking
- `memory_stress` — pipelined writes to fill `maxmemory` and trigger evictions
- `connection_exhaustion` — raw TCP/RESP connection flooding
- `connection_orchestrator` — fan-out orchestrator for massive connection counts
- `failover` — triggers `TestFailover` on the replication group
- `cleanup` — deletes stress keys by prefix

## Usage

```hcl
module "elasticache_stress_test" {
  source = "./terraform/aws/modules/composition/elasticache-stress-test"

  region      = "us-east-1"
  environment = "dev"

  redis_endpoint    = "my-cluster.xxx.cache.amazonaws.com"
  redis_port        = 6379
  redis_cluster_mode = false

  vpc_id                   = "vpc-12345678"
  lambda_subnet_ids        = ["subnet-11111111", "subnet-22222222"]
  lambda_security_group_id = "sg-jumphost"
  redis_security_group_id  = "sg-elasticache"

  redis_replication_group_id = "my-redis"
  redis_node_group_id        = "0001"

  tags = {
    Project = "my-project"
  }
}
```

## Required inputs

- `region`
- `environment`
- `redis_endpoint`
- `vpc_id`
- `lambda_subnet_ids`
- `lambda_security_group_id` or `create_security_group = true` + `redis_security_group_id`

## Optional highlights

- `workload_*` variables — tune the open-loop mixed workload
- `cpu_phase_*` variables — tune phased CPU stress
- `memory_phase_*` variables — tune phased memory stress
- `connection_target_total` / `connection_rapid_churn` — connection exhaustion behavior
- `workload_emit_cloudwatch_metrics` — emit custom CloudWatch metrics per phase

See `variables.tf` for the full input list and `outputs.tf` for emitted function names and ARNs.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.4 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.stress_test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cloudwatch_metrics](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.elasticache_failover](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.lambda_invoke_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.stress_test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_security_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.redis_ingress_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [archive_file.stress_test_code](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_connection_batch_size"></a> [connection\_batch\_size](#input\_connection\_batch\_size) | Number of raw TCP sockets opened per batch per worker in connection exhaustion test | `number` | `100` | no |
| <a name="input_connection_rapid_churn"></a> [connection\_rapid\_churn](#input\_connection\_rapid\_churn) | If true, after reaching connection\_target\_total workers churn (open/handshake/close) while holding the pool | `bool` | `false` | no |
| <a name="input_connection_target"></a> [connection\_target](#input\_connection\_target) | Target number of concurrent connections for connection exhaustion test (legacy; prefer connection\_target\_total) | `number` | `1000` | no |
| <a name="input_connection_target_total"></a> [connection\_target\_total](#input\_connection\_target\_total) | Total number of held connections across all workers before switching to churn mode | `number` | `850` | no |
| <a name="input_connection_threads"></a> [connection\_threads](#input\_connection\_threads) | Number of worker threads for connection exhaustion test | `number` | `48` | no |
| <a name="input_cpu_burn_iterations"></a> [cpu\_burn\_iterations](#input\_cpu\_burn\_iterations) | Number of Lua iterations in the CPU stress script (default 500k ≈ 20-50ms on cache.m6g.large) | `number` | `500000` | no |
| <a name="input_cpu_mixed_mode"></a> [cpu\_mixed\_mode](#input\_cpu\_mixed\_mode) | If true, CPU stress mixes SET/GET/INCR with Lua burn. If false, runs pure Lua burn (higher EngineCPU). | `bool` | `false` | no |
| <a name="input_cpu_phase_cycle_period_seconds"></a> [cpu\_phase\_cycle\_period\_seconds](#input\_cpu\_phase\_cycle\_period\_seconds) | Max random startup jitter in seconds for CPU stress workers (e.g. 2). Small jitter is enough when per-cycle jitter is also applied; large jitter distorts 1-minute CloudWatch averages. | `number` | `2` | no |
| <a name="input_cpu_phase_durations"></a> [cpu\_phase\_durations](#input\_cpu\_phase\_durations) | Comma-separated phase durations in seconds for staged CPU stress (e.g. 60,300,300 = 1min warmup + 5min + 5min) | `string` | `"60,180,180"` | no |
| <a name="input_cpu_phase_duty"></a> [cpu\_phase\_duty](#input\_cpu\_phase\_duty) | Comma-separated duty cycles per CPU stress phase (e.g. 0.97,0.98,1.0). Values <1.0 throttle the aggregate offered load so EngineCPU stays below 100%. | `string` | `"0.97,0.98,1.0"` | no |
| <a name="input_cpu_phase_threads"></a> [cpu\_phase\_threads](#input\_cpu\_phase\_threads) | Comma-separated thread counts per CPU stress phase (e.g. 8,8,8). With the linear D/N duty model, 8 threads is usually enough for a smooth 90-97% EngineCPU plateau. | `string` | `"8,8,8"` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Create a dedicated security group for Lambda. If false, provide lambda\_security\_group\_id (e.g., reuse jump host SG) | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment short name for resource naming (e.g., sbx, prod) | `string` | n/a | yes |
| <a name="input_failover_poll_interval_seconds"></a> [failover\_poll\_interval\_seconds](#input\_failover\_poll\_interval\_seconds) | Polling interval in seconds between describe\_replication\_groups calls during failover recovery | `number` | `15` | no |
| <a name="input_failover_timeout_seconds"></a> [failover\_timeout\_seconds](#input\_failover\_timeout\_seconds) | Maximum time in seconds to wait for the replication group to return to available after TestFailover | `number` | `600` | no |
| <a name="input_key_prefix"></a> [key\_prefix](#input\_key\_prefix) | Prefix for all keys created by stress tests (used by cleanup function) | `string` | `"stress:test:"` | no |
| <a name="input_lambda_layers"></a> [lambda\_layers](#input\_lambda\_layers) | List of Lambda layer ARNs (e.g., existing redis-py-python311 layer) | `list(string)` | `[]` | no |
| <a name="input_lambda_memory_size"></a> [lambda\_memory\_size](#input\_lambda\_memory\_size) | Lambda memory size in MB for stress test functions | `number` | `512` | no |
| <a name="input_lambda_runtime"></a> [lambda\_runtime](#input\_lambda\_runtime) | Lambda runtime (must match compatible\_runtimes of the redis-py layer) | `string` | `"python3.11"` | no |
| <a name="input_lambda_security_group_id"></a> [lambda\_security\_group\_id](#input\_lambda\_security\_group\_id) | Existing security group ID for Lambda (required when create\_security\_group = false) | `string` | `""` | no |
| <a name="input_lambda_subnet_ids"></a> [lambda\_subnet\_ids](#input\_lambda\_subnet\_ids) | List of subnet IDs for Lambda VPC config (use lambda subnets) | `list(string)` | n/a | yes |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Lambda timeout in seconds for stress test functions (max 900) | `number` | `900` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log group retention in days | `number` | `14` | no |
| <a name="input_memory_cleanup_after_stress"></a> [memory\_cleanup\_after\_stress](#input\_memory\_cleanup\_after\_stress) | If true, memory\_stress automatically unlinks all stress keys before returning | `bool` | `true` | no |
| <a name="input_memory_key_count"></a> [memory\_key\_count](#input\_memory\_key\_count) | Number of keys to write for memory stress test (legacy; prefer memory\_keys\_per\_worker) | `number` | `10000` | no |
| <a name="input_memory_keys_per_worker"></a> [memory\_keys\_per\_worker](#input\_memory\_keys\_per\_worker) | Number of keys each memory stress worker writes before stopping | `number` | `5000` | no |
| <a name="input_memory_phase_durations"></a> [memory\_phase\_durations](#input\_memory\_phase\_durations) | Comma-separated phase durations in seconds for staged memory stress (e.g. 240,240,240) | `string` | `"240,240,240"` | no |
| <a name="input_memory_phase_target_percent"></a> [memory\_phase\_target\_percent](#input\_memory\_phase\_target\_percent) | Comma-separated target used\_memory percentages of maxmemory per memory stress phase (e.g. 60,85,100) | `string` | `"60,85,100"` | no |
| <a name="input_memory_phase_workers"></a> [memory\_phase\_workers](#input\_memory\_phase\_workers) | Comma-separated writer counts per memory stress phase (e.g. 8,12,24) | `string` | `"8,12,24"` | no |
| <a name="input_memory_pipeline_size"></a> [memory\_pipeline\_size](#input\_memory\_pipeline\_size) | Number of SET commands per pipeline batch in memory stress test | `number` | `5` | no |
| <a name="input_memory_value_size_kb"></a> [memory\_value\_size\_kb](#input\_memory\_value\_size\_kb) | Size of each value in KB for memory stress test | `number` | `4096` | no |
| <a name="input_memory_workers"></a> [memory\_workers](#input\_memory\_workers) | Number of per-worker threads (each with its own redis client) for memory stress test | `number` | `24` | no |
| <a name="input_memory_write_ttl"></a> [memory\_write\_ttl](#input\_memory\_write\_ttl) | TTL in seconds for memory stress keys (0 = no TTL, keys persist until eviction or cleanup) | `number` | `0` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | `""` | no |
| <a name="input_redis_auth_token"></a> [redis\_auth\_token](#input\_redis\_auth\_token) | AUTH token for Redis (if enabled). Leave empty for no AUTH. | `string` | `""` | no |
| <a name="input_redis_cluster_mode"></a> [redis\_cluster\_mode](#input\_redis\_cluster\_mode) | Whether Redis has cluster mode enabled. If true, uses redis.cluster.RedisCluster client connecting to configuration endpoint. If false, uses redis.Redis client connecting to primary endpoint. | `bool` | `true` | no |
| <a name="input_redis_endpoint"></a> [redis\_endpoint](#input\_redis\_endpoint) | Elasticache Redis/Valkey endpoint (configuration endpoint for cluster mode, primary endpoint for standalone) | `string` | n/a | yes |
| <a name="input_redis_node_group_id"></a> [redis\_node\_group\_id](#input\_redis\_node\_group\_id) | ElastiCache node group / shard ID for the failover Lambda (e.g., 0001) | `string` | `"0001"` | no |
| <a name="input_redis_port"></a> [redis\_port](#input\_redis\_port) | Redis/Valkey port | `number` | `6379` | no |
| <a name="input_redis_replication_group_id"></a> [redis\_replication\_group\_id](#input\_redis\_replication\_group\_id) | ElastiCache replication group ID for the failover Lambda (TestFailover API) | `string` | `""` | no |
| <a name="input_redis_security_group_id"></a> [redis\_security\_group\_id](#input\_redis\_security\_group\_id) | Redis security group ID (required when create\_security\_group = true, to add ingress rule for port 6379) | `string` | `""` | no |
| <a name="input_redis_use_tls"></a> [redis\_use\_tls](#input\_redis\_use\_tls) | Whether Redis has TLS enabled (transit\_encryption\_enabled) | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_stress_clients"></a> [stress\_clients](#input\_stress\_clients) | Default number of concurrent clients/connections for stress tests | `number` | `50` | no |
| <a name="input_stress_duration"></a> [stress\_duration](#input\_stress\_duration) | Default stress test duration in seconds | `number` | `300` | no |
| <a name="input_stress_threads"></a> [stress\_threads](#input\_stress\_threads) | Default number of worker threads for stress tests | `number` | `4` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where Lambda functions will be deployed | `string` | n/a | yes |
| <a name="input_workload_command_mix"></a> [workload\_command\_mix](#input\_workload\_command\_mix) | Command mix for mixed workload stress as command:weight pairs (e.g. get:60,set:20,hget:10,hset:5,incr:5). Weights are normalised by their total. | `string` | `"get:60,set:20,hget:10,hset:5,incr:5"` | no |
| <a name="input_workload_emit_cloudwatch_metrics"></a> [workload\_emit\_cloudwatch\_metrics](#input\_workload\_emit\_cloudwatch\_metrics) | If true, mixed workload stress emits custom CloudWatch metrics (Operations, Errors, P50Latency, P99Latency) per phase | `bool` | `false` | no |
| <a name="input_workload_key_count"></a> [workload\_key\_count](#input\_workload\_key\_count) | Upper bound for random key ID selection in mixed workload stress (keys are in [0, workload\_key\_count)) | `number` | `100000` | no |
| <a name="input_workload_key_pattern"></a> [workload\_key\_pattern](#input\_workload\_key\_pattern) | Key pattern for mixed workload stress. Use {id} as placeholder for random integer in [0, workload\_key\_count) | `string` | `"stress:test:{id}"` | no |
| <a name="input_workload_phase_cycle_period_seconds"></a> [workload\_phase\_cycle\_period\_seconds](#input\_workload\_phase\_cycle\_period\_seconds) | Max random startup jitter in seconds for mixed workload workers (desynchronises thread send schedules) | `number` | `2` | no |
| <a name="input_workload_phase_durations"></a> [workload\_phase\_durations](#input\_workload\_phase\_durations) | Comma-separated phase durations in seconds for mixed workload stress (e.g. 60,180,180) | `string` | `"60,180,180"` | no |
| <a name="input_workload_phase_ops_per_sec"></a> [workload\_phase\_ops\_per\_sec](#input\_workload\_phase\_ops\_per\_sec) | Comma-separated target total ops/sec per mixed workload phase (e.g. 20000,35000,45000) | `string` | `"20000,35000,45000"` | no |
| <a name="input_workload_pipeline_size"></a> [workload\_pipeline\_size](#input\_workload\_pipeline\_size) | Number of commands per pipeline batch in mixed workload stress (1 = no pipelining) | `number` | `1` | no |
| <a name="input_workload_threads"></a> [workload\_threads](#input\_workload\_threads) | Number of worker threads for mixed workload stress (each with its own Redis client). Dedicated knob so the generator can scale independently of other stress types. | `number` | `32` | no |
| <a name="input_workload_value_size_bytes"></a> [workload\_value\_size\_bytes](#input\_workload\_value\_size\_bytes) | Size of random byte string values for SET/HSET commands in mixed workload stress | `number` | `256` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_invoke_commands"></a> [invoke\_commands](#output\_invoke\_commands) | AWS CLI commands to invoke each stress test Lambda function |
| <a name="output_lambda_function_arns"></a> [lambda\_function\_arns](#output\_lambda\_function\_arns) | Map of stress type to Lambda function ARN |
| <a name="output_lambda_function_names"></a> [lambda\_function\_names](#output\_lambda\_function\_names) | Map of stress type to Lambda function name |
| <a name="output_lambda_iam_role_arn"></a> [lambda\_iam\_role\_arn](#output\_lambda\_iam\_role\_arn) | ARN of the Lambda IAM role |
| <a name="output_lambda_layers"></a> [lambda\_layers](#output\_lambda\_layers) | Lambda layer ARNs used by the stress test functions |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group ID used by Lambda functions (created or reused) |
<!-- END_TF_DOCS -->