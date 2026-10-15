# Fault Injection & Chaos Testing for Self-Hosted Storage

This directory contains a set of Terraform modules that let you reproduce chaos
and fault-injection experiments against the storage layer of a self-hosted
deployment:

- **Amazon Aurora PostgreSQL** (RDS Aurora) — resource stress and crash/failover
  augmentation.
- **Amazon ElastiCache Redis / Valkey** — resource stress and failover.
- **AWS Fault Injection Simulator (FIS)** — orchestration with automatic
  stop conditions.

The modules are intentionally generic and are shipped separately from any live
environment. Each module has its own `README.md`; this document explains how the
pieces fit together, the prerequisites, and how to run an experiment safely.

## Modules

| Module | Purpose |
|--------|---------|
| `aurora-fault-injection` | Lambda functions that stress Aurora PostgreSQL (CPU, memory and connection exhaustion) plus a set of crash, disk and replica-failure fault-injection handlers. See [README](./aurora-fault-injection/README.md). |
| `elasticache-stress-test` | Lambda functions for ElastiCache Redis/Valkey: CPU, memory and connection exhaustion (with an orchestrator for fan-out), `TestFailover`, a mixed read/write workload, and cleanup. See [README](./elasticache-stress-test/README.md). |
| `fis-experiments` | FIS experiment templates, the FIS execution IAM role, and CloudWatch stop-condition alarms. See [README](./fis-experiments/README.md). |
| `lambda-layer` | Shared Lambda layer used by the functions above (e.g. drivers such as `psycopg2` and `redis-py`). See [README](./lambda-layer/README.md). |

## Architecture

```
              +---------------------------+
              |    AWS Fault Injection    |
              |      Simulator (FIS)      |
              +-------------+-------------+
                            |
              native actions |  SSM Run Command
              (RDS failover, |  (aws-ssm:send-command
               reboot, EC2)  |   on a jump host)
                            |
              +-------------v-------------+
              |        Jump host          |
              |  (SSM-managed bastion)    |
              +-------------+-------------+
                            |
              aws:lambda:invoke
                            |
              +-------------v-------------+
              |   Stress / fault-inject   |
              |        Lambdas            |
              |  (lambda-layer + drivers) |
              +-------------+-------------+
                            |
                         in-VPC
                +----------+----------+
                |                     |
      +---------v---------+  +--------v---------+
      |  Aurora PostgreSQL |  | ElastiCache Redis|
      |   (stress / crash  |  | / Valkey (stress |
      |   / failover)      |  | / failover)      |
      +-------------------+  +------------------+
```

FIS has no native CPU, memory or connection-stress action for managed Aurora or
ElastiCache, so those experiments are backed by Lambda functions. FIS runs an
SSM command on a jump host, which in turn calls `aws lambda invoke`. Aurora
cluster failover, RDS reboot, EC2 termination and network latency injection use
native FIS actions or AWS-provided SSM documents.

## Prerequisites

Before you deploy these modules you need:

- **Existing VPC and subnets.** The Lambda functions must run inside the same
  VPC as the database and cache so they can reach them. Provide private
  subnets for the Lambdas.
- **Security groups.** The database and cache security groups must allow ingress
  from the Lambda security group on the relevant ports (5432 for Aurora,
  6379 for Redis/Valkey). The modules can either create a dedicated Lambda
  security group or reuse an existing one (for example the jump host SG).
- **Credentials.**
  - Aurora: a database user with privileges to run `pgbench`-style load and the
    Aurora fault-injection SQL functions. Credentials are stored in AWS Secrets
    Manager and encrypted with a KMS key. The secrets payload must contain
    `username`, `password`, `host`, `port`, `dbname`. The password may be stored
    either as plaintext or KMS-encrypted base64.
  - Redis/Valkey: an endpoint (configuration endpoint for cluster mode, primary
    endpoint for standalone), an optional AUTH token, and TLS setting.
- **Lambda layers.** The Aurora functions use a `psycopg2` layer and the
  ElastiCache stress functions use a `redis-py` layer. Publish these with the
  `lambda-layer` module and pass the ARNs to the `lambda_layers` variable of
  each module. See [Lambda layers](#lambda-layers) below for how to build the
  zip and pass it in.
- **A jump host.** An SSM-managed EC2 instance with outbound access to the
  Lambdas. FIS uses `aws-ssm:send-command` to invoke the stress Lambdas. Its
  instance ARN is passed to `fis-experiments`.
- **AWS account and region** where all resources live.

## Lambda layers

The stress and fault-injection Lambdas depend on additional Python packages that
are not in the Lambda Python runtime image, so you must publish them as Lambda
layers and pass the layer ARNs into the modules.

| Module | Functions that need a layer | Layer |
|--------|-----------------------------|-------|
| `aurora-fault-injection` | `fault_injection` handlers (crash/disk/replica) and `stress_test` (cpu/memory/connection/cleanup) | `psycopg2` |
| `elasticache-stress-test` | `cpu_stress`, `memory_stress`, `mixed_workload`, `connection_exhaustion`, `cleanup`, `connection_orchestrator` | `redis-py` (the `redis` package, with cluster support) |
| `elasticache-stress-test` | `failover` | none — uses only `boto3`, which is built into the runtime |

For a Python Lambda layer the zip must contain the installed package under a
top-level `python/` directory. Build it from an Amazon Linux 2 / 2023 compatible
environment so the compiled extensions match the Lambda runtime:

```bash
# psycopg2 layer
mkdir -p python
pip install psycopg2-binary --target python
zip -r psycopg2.zip python

# redis-py layer (manylinux wheels, no compilation needed for the pure-Python parts)
mkdir -p python
pip install redis --target python
zip -r redis-py.zip python
```

Then publish each zip with the `lambda-layer` module and pass the resulting ARN
to the relevant module via the `lambda_layers` variable. Because
`lambda_layers` is a list, you can also reference a layer published
independently (for example an account-wide `psycopg2` layer) instead of
deploying one with this module:

```hcl
module "psycopg2_layer" {
  source       = "./terraform/aws/modules/composition/lambda-layer"
  layer_name   = "psycopg2"
  zip_path     = "${path.module}/psycopg2.zip"  # built as above
}

module "redis_py_layer" {
  source       = "./terraform/aws/modules/composition/lambda-layer"
  layer_name   = "redis-py"
  zip_path     = "${path.module}/redis-py.zip"  # built as above
}

# Existing layers published outside this module can be referenced by ARN directly:
variable "existing_redis_py_layer_arn" {
  type    = string
  default = ""
}

locals {
  redis_layers = var.existing_redis_py_layer_arn != ""
    ? [var.existing_redis_py_layer_arn]
    : [module.redis_py_layer.layer_arn]
}
```

See the [lambda-layer](./lambda-layer/README.md) module README for the full
input list (`zip_path`, `source_hash`, `compatible_runtimes`, `license_info`).

## Quick wiring example

The four modules are usually instantiated together. A minimal wire-up (the
`psycopg2_layer` and `redis_py_layer` modules are defined in the
[Lambda layers](#lambda-layers) section above):

```hcl
# Layer modules (psycopg2_layer, redis_py_layer) are defined in the
# "Lambda layers" section above and referenced here.

# 1. Aurora stress + fault injection Lambdas
module "aurora_fault_injection" {
  source = "./terraform/aws/modules/composition/aurora-fault-injection"

  region                  = var.region
  environment             = var.environment
  db_endpoint             = aws_rds_cluster.this.endpoint
  db_password             = var.db_password
  vpc_id                  = var.vpc_id
  lambda_subnet_ids       = var.lambda_subnet_ids
  lambda_security_group_id = var.lambda_security_group_id
  enable_stress_tests     = true
  lambda_layers           = [module.psycopg2_layer.layer_arn]
}

# 2. ElastiCache stress + failover Lambdas
module "elasticache_stress_test" {
  source = "./terraform/aws/modules/composition/elasticache-stress-test"

  region                   = var.region
  environment              = var.environment
  redis_endpoint           = aws_elasticache_replication_group.this.configuration_endpoint_address
  vpc_id                   = var.vpc_id
  lambda_subnet_ids        = var.lambda_subnet_ids
  lambda_security_group_id = var.lambda_security_group_id
  redis_replication_group_id = aws_elasticache_replication_group.this.id
  lambda_layers            = local.redis_layers
}

# 3. FIS experiments + stop conditions
module "fis_experiments" {
  source = "./terraform/aws/modules/composition/fis-experiments"

  region              = var.region
  environment         = var.environment
  account_id          = var.account_id
  rds_cluster_arn     = aws_rds_cluster.this.arn
  rds_cluster_identifier = aws_rds_cluster.this.id
  rds_instance_arns   = [for i in aws_rds_cluster_instance.this : i.arn]

  jumphost_instance_id = var.jumphost_instance_id

  stress_lambda_arns = values(module.aurora_fault_injection.stress_test_function_arns)
  stress_lambda_function_names = module.aurora_fault_injection.stress_test_function_names

  redis_stress_lambda_arns = [
    module.elasticache_stress_test.lambda_function_arns["cpu_stress"],
    module.elasticache_stress_test.lambda_function_arns["memory_stress"],
    module.elasticache_stress_test.lambda_function_arns["connection_exhaustion"],
  ]
  redis_stress_lambda_function_names = {
    cpu_stress            = module.elasticache_stress_test.lambda_function_names["cpu_stress"]
    memory_stress         = module.elasticache_stress_test.lambda_function_names["memory_stress"]
    connection_exhaustion = module.elasticache_stress_test.lambda_function_names["connection_exhaustion"]
  }
  redis_replication_group_id = aws_elasticache_replication_group.this.id
  redis_failover_lambda_function_name = module.elasticache_stress_test.lambda_function_names["failover"]
  redis_failover_lambda_function_arn  = module.elasticache_stress_test.lambda_function_arns["failover"]
}
```

`terraform validate` and `terraform plan` against your live layer will confirm
the actual wiring; see each module's `variables.tf` for the full input surface.

## Experiment catalog

The `fis-experiments` module can create the following experiment templates:

| Experiment | Type | Enabled by default |
|------------|------|--------------------|
| Aurora cluster failover | Native FIS (`aws:rds:cluster-failover`) | yes |
| DB instance reboot | Native FIS (`aws:rds:reboot-db-instances`) | yes |
| Combined failover + wait + reboot | Compound | yes |
| Network connectivity loss to DB | Network disruption (SG/ENI deny) | no |
| DB AZ power interruption | Compound (disruption + reboot) | no |
| EC2 network latency injection | `aws:ssm:send-command` + `AWSFIS-Run-Network-Latency-Sources` (tc netem) | no |
| Simple all-traffic network latency | `AWSFIS-Run-Network-Latency` | no |
| CPU / memory / connection stress (Aurora) | SSM on jump host → Lambda | no |
| CPU / memory stress + failover-under-stress (Redis) | SSM on jump host → Lambda | no |
| Redis replication group failover (`TestFailover`) | SSM on jump host → Lambda | no |
| EC2 instance termination | Native FIS (`aws:ec2:terminate-instances`) | no |

Templates that are created but not enabled by default are not run until you
explicitly enable the corresponding `enable_*` toggle and any required target
ARNs/ids.

## Stop conditions

The `fis-experiments` module creates CloudWatch alarms that FIS uses as stop
conditions. Review and tune these per experiment; the defaults are:

**Aurora (RDS)**
- `CPUUtilization` > 95% (average, 2m)
- `FreeableMemory` < ~2 GB (minimum, 2m)
- `DatabaseConnections` > 68 (maximum, 2m) — only when `enable_stress_alarms` is set

**Redis/Valkey (ElastiCache)**
- `EngineCPUUtilization` > 90% (average, 2m)
- `FreeableMemory` < 100 MB (minimum, 2m)
- `CurrConnections` > 64,000 (maximum, 2m)
- `ReplicationLag` > 60 s (maximum, 2m)

The defaults are intentionally conservative. If your stress target has a higher
connection ceiling than the values above, update the thresholds so a legitimate
stress experiment does not trip the stop condition prematurely.

## Safety first

- **CPU / memory / connection stress, Redis failover templates and EC2
  termination are disabled by default.** Enable them only when you intend to run
  the experiment.
- **EC2 instance termination permanently destroys the instances it targets.**
  Only point it at disposable, non-production instances.
- **Failover, reboot and combined-failover templates are enabled by default but
  are created, not run.** FIS does not start an experiment until you start it.
- **Run experiments in a staging environment first**, with synthetic traffic
  flowing and the stop alarms attached, before touching anything production-like.
- Aurora crash handlers (`crash_instance`, `crash_dispatcher`, `crash_node`)
  and `disk_failure`/`disk_congestion` call Aurora native fault-injection
  functions. Confirm they are available on your engine version and that the
  target is a disposable test cluster.
- The stress Lambdas create data (for example `pgbench` tables on Aurora and
  `stress:test:` keys on Redis). Use the provided `cleanup` functions and drop
  the test schema after a run.

## Running an experiment

1. Deploy the modules into the target environment (Lambdas, layer, alarms,
   FIS templates).
2. Confirm the stop-condition alarms are in `OK` state.
3. Start the experiment from the AWS console or CLI:

   ```bash
   aws fis start-experiment \
     --experiment-template-id <template-id> \
     --region <region>
   ```

4. Watch the relevant CloudWatch metrics (CPU, memory, connections, replica
   lag) while the experiment runs. The stop alarms should abort the experiment
   automatically if a safety threshold is breached.
5. After the run, clean up: run the `cleanup` Lambdas and drop the generated
   `pgbench` tables / stress keys.

## Scope and footprint

Each module creates only the resources it needs and is self-contained — there
are no cross-module hard dependencies, so you can deploy any subset (for
example, only the ElastiCache stress module) independently. All resources are
tagged via the `tags` variable and named with an `environment` prefix to avoid
collisions across environments.

## See also

- `aurora-fault-injection/README.md`
- `elasticache-stress-test/README.md`
- `fis-experiments/README.md`
- `lambda-layer/README.md`
- [AWS Fault Injection Simulator documentation](https://docs.aws.amazon.com/fis/latest/userguide/)