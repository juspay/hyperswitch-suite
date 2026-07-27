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
