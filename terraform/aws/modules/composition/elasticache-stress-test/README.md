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

  # The stress-test Lambdas (except `failover`) need the redis-py layer.
  # Publish it with the lambda-layer module and pass the ARN here.
  lambda_layers = [module.redis_py_layer.layer_arn]

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

## Prerequisites

- **VPC & subnets.** The stress Lambdas run in the same VPC as the ElastiCache
  cluster. Provide private `lambda_subnet_ids`. The `failover` Lambda needs no
  VPC config (it only calls the ElastiCache API).
- **Security group.** The ElastiCache SG must allow ingress from the Lambda SG
  on `6379`.
- **Endpoint + auth.** Provide the configuration endpoint (cluster mode) or the
  primary endpoint (standalone), an optional AUTH token, and the TLS setting.
- **Lambda layer.** The stress Lambdas import `redis-py`. Publish a `redis-py`
  layer (see the `lambda-layer` module) and pass its ARN via `lambda_layers`.
  The `failover` function uses only `boto3` and needs no layer.

## Invoking each function

Every stress Lambda is invoked with an empty JSON payload; behavior is driven by
its environment variables (controlled by the module variables above):

```bash
aws lambda invoke --function-name "<env>-elasticache-stress-<type>" \
  --region <region> --payload '{}' /tmp/<type>-output.json \
  && cat /tmp/<type>-output.json
```

The module exposes ready-made commands for every function via the
`invoke_commands` output.

| Function | What it does | Notes |
|----------|--------------|-------|
| `cpu_stress` | Runs concurrent SET/GET/INCR plus a Lua script CPU burn in phases (or flat mode) targeting an EngineCPU plateau. Avenues: `cpu_phase_*`, `CPU_MIXED_MODE`, `CPU_BURN_ITERATIONS` | |
| `mixed_workload` | Open-loop mixed command workload (GET/SET/HGET/HSET/INCR) at a fixed arrival rate with latency percentile measurement; optional CloudWatch metrics. Avenues: `workload_*` | |
| `memory_stress` | Pipeline-writes large values to fill `maxmemory` and force evictions. Avenues: `memory_phase_*` | Generates keys under `KEY_PREFIX` |
| `connection_exhaustion` | Floods connections to exhaust `maxclients`. Avenues: `connection_*`, `CONN_PHASE_THREADS` | |
| `connection_orchestrator` | Fans out to many `connection_exhaustion` workers and centrally manages `maxclients` for very large connection counts | |
| `failover` | Triggers `elasticache:TestFailover` on the replication group node group and polls until the group returns to `available` | See failover notes below |
| `cleanup` | Deletes all keys under the stress `KEY_PREFIX` | Run after any memory/mixed stress |

## Failover (`failover`)

The `failover` Lambda runs pre-flight checks before calling `TestFailover`:

- The replication group status must be `available`.
- The target node group must have at least 2 members (primary + replica).
- Every replica must have `ReplicaLag` <= 30s (skipped when the metric is absent).
- No node replacement/failover may already be in progress.

It then polls `describe_replication_groups` until the group returns to
`available` (up to `failover_timeout_seconds`). The target replication group is
**required** input via `redis_replication_group_id`; if it is left unset the
function returns `400`.

> **Safety.** Failover flips the primary to a replica. Run it against a
> disposable test cluster first, with a low `ReplicationLag` (see
> `fis-experiments` stop-condition alarm), and confirm writes recover once the
> group is `available` again.

## Cleanup after stress

The `memory_stress` and `mixed_workload` functions write keys under
`KEY_PREFIX` (`stress:test:` by default). Run the `cleanup` function (or let
`memory_cleanup_after_stress` auto-unlink on completion) to remove them after a
run.

See `outputs.tf` for the emitted function ARNs/names and ready-made invoke commands.