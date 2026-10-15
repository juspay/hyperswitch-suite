# Aurora Fault Injection & Stress Test Module

Generic Terraform module that deploys Lambda-based fault injection and stress tests for Amazon Aurora PostgreSQL.

The module provides two groups of Lambdas:

- **Fault injection** (`src/aurora_inject/`) — six handlers that call Aurora's
  native fault-injection SQL functions to crash or damage instances, replicas
  or disks.
- **Stress testing** (`src/stress_test/`) — optional handlers that generate CPU,
  memory and connection pressure, plus a cleanup handler.

## What it creates

- KMS key + Secrets Manager secret for Aurora credentials
- IAM role for Lambda with VPC, Secrets Manager, and KMS access
- Optional Lambda security group (or reuse an existing one)
- Six fault-injection Lambda functions (`crash_instance`, `crash_dispatcher`, `crash_node`, `replica_failure`, `disk_failure`, `disk_congestion`)
- Optional stress-test Lambda functions (`cpu_stress`, `memory_stress`, `connection_exhaustion`, `cleanup`)

## Usage

```hcl
module "aurora_fault_injection" {
  source = "./terraform/aws/modules/composition/aurora-fault-injection"

  region      = "us-east-1"
  environment = "dev"

  db_endpoint = "my-cluster.cluster-xyz.us-east-1.rds.amazonaws.com"
  db_name     = "postgres"
  db_username = "postgres"
  db_password = sensitive("supersecret")

  vpc_id                  = "vpc-12345678"
  lambda_subnet_ids       = ["subnet-11111111", "subnet-22222222"]
  lambda_security_group_id = "sg-jumphost"

  # The stress-test Lambdas need the psycopg2 Lambda layer. Publish it with the
  # lambda-layer module and pass the ARN here.
  lambda_layers     = [module.psycopg2_layer.layer_arn]
  enable_stress_tests = true

  tags = {
    Project = "my-project"
  }
}
```

## Required inputs

- `region`
- `environment`
- `db_endpoint`
- `db_password`
- `vpc_id`
- `lambda_subnet_ids`
- `lambda_security_group_id` (if `create_security_group = false`)

## Optional highlights

- `enable_stress_tests` — deploy CPU/memory/connection stress Lambdas
- `create_security_group` / `db_security_group_id` — control SG creation
- `create_secret` / `secret_name` — use module-managed or existing Secrets Manager secret
- `lambda_layers` — ARNs of the `psycopg2` layer required by the fault & stress Lambdas

See `variables.tf` for the full input list and `outputs.tf` for emitted ARNs and experiment IDs.

## Prerequisites

- **VPC & subnets.** The Lambdas must run in the same VPC as the Aurora cluster
  so they can reach it. Provide private `lambda_subnet_ids`.
- **Security group.** The Aurora cluster SG must allow ingress from the Lambda
  SG on `5432`. Use `create_security_group = false` + `lambda_security_group_id`
  to reuse an SG, or `create_security_group = true` + `db_security_group_id`.
- **Credentials.** A database user able to run the aurora fault-injection SQL
  functions and pgbench-style load. Credentials go into AWS Secrets Manager,
  encrypted with KMS. The secret payload must contain `username`, `password`,
  `host`, `port`, `dbname`. The password may be plaintext or KMS-encrypted
  base64.
- **Lambda layer.** Both the fault and stress Lambdas import `psycopg2`. Publish
  a `psycopg2` layer (see the `lambda-layer` module) and pass its ARN via
  `lambda_layers`.

## Fault injection cases

Each fault handler is a separate Lambda. Invoke any of them with the AWS CLI
from a jump host, your workstation, or a FIS experiment:

```bash
aws lambda invoke --function-name "<env>-aurora-fi-<fault>" --region <region> \
  --payload '{}' /tmp/<fault>-output.json && cat /tmp/<fault>-output.json
```

The module exposes ready-made commands via the `invoke_commands` output.

| Function | SQL executed | Effect |
|----------|--------------|--------|
| `crash_instance` | `aurora_inject_crash('instance')` | Crashes the database endpoint process on the instance |
| `crash_dispatcher` | `aurora_inject_crash('dispatcher')` | Crashes the DB dispatcher process (writes to the cluster volume) |
| `crash_node` | `aurora_inject_crash('node')` | Crashes both the instance and dispatcher (node) |
| `replica_failure` | `aurora_inject_replica_failure(100, 30)` | Fails 100% of replica reads for 30s |
| `disk_failure` | `aurora_inject_disk_failure(50, 0, false, 20)` | Fails 50% of storage I/O, no recovery, for 20s |
| `disk_congestion` | `aurora_inject_disk_congestion(100, 0, true, 60, 30.0, 100.0)` | Congests 100% of I/O for 60s with 30–100ms delay |

> **Safety.** Crash and disk handlers actually disrupt the target. Only point
> them at a disposable test cluster, and confirm the `aurora_inject_*` functions
> are available on your Aurora engine version. A connection drop during a crash
> fault is expected and reported as `crash_injected` rather than an error.

## Stress test cases (`enable_stress_tests = true`)

The stress handlers run for a few minutes each and create data that must be
cleaned up afterwards. Invoke them the same way (the module exposes
`stress_test_invoke_commands`):

```bash
aws lambda invoke --function-name "<env>-aurora-stress-<type>" --region <region> \
  --payload '{}' /tmp/<type>-output.json && cat /tmp/<type>-output.json
```

| Function | What it does |
|----------|--------------|
| `cpu_stress` | Runs a TPC-B-like concurrent workload (SELECT/INSERT/UPDATE) with phased thread/duty settings to push instance CPU toward a target |
| `memory_stress` | Opens idle connections and runs large `work_mem` sorts / `array_agg` aggregation to drive memory pressure |
| `connection_exhaustion` | Opens many concurrent connections in phases to exhaust the connection pool |
| `cleanup` | Drops the `pgbench_*` tables (`pgbench_accounts`, `pgbench_branches`, `pgbench_tellers`, `pgbench_history`) created by the stress tests |

Tune behavior with the `cpu_phase_*`, `mem_phase_*`, and `conn_phase_*`
variables (see `variables.tf`). **Always run `cleanup` after a stress test** to
remove the pgbench schema.

See `outputs.tf` for the emitted function ARNs/names and ready-made invoke commands.