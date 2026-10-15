# AWS FIS Chaos Experiments Module

Generic Terraform module that creates AWS Fault Injection Service (FIS) experiment templates for RDS Aurora, ElastiCache Redis/Valkey, EC2, and network paths.

FIS has no native CPU, memory or connection-stress action for managed Aurora or
ElastiCache, so those experiments are backed by Lambda functions. FIS runs an
SSM command on a jump host, which in turn invokes the stress Lambda. Aurora
cluster failover, RDS reboot, EC2 termination and network latency use native FIS
actions or AWS-provided SSM documents.

## What it creates

- FIS execution IAM role with policies for RDS, EC2, ElastiCache, Lambda, SSM, CloudWatch, and KMS
- CloudWatch stop-condition alarms
- FIS experiment templates:
  - Aurora cluster failover
  - RDS DB instance reboot
  - Combined failover + wait + reboot
  - Network connectivity loss to DB
  - AZ power interruption
  - EC2 network latency injection (via SSM / tc netem)
  - EC2 instance termination
  - CPU/memory/connection stress via Lambda (Aurora and Redis)
  - Redis replication group failover and failover-under-stress

## Usage

```hcl
module "fis_experiments" {
  source = "./terraform/aws/modules/composition/fis-experiments"

  region      = "us-east-1"
  environment = "dev"
  account_id  = "123456789012"

  rds_cluster_arn      = "arn:aws:rds:us-east-1:123456789012:cluster:my-cluster"
  rds_cluster_identifier = "my-cluster"
  rds_instance_arns    = ["arn:aws:rds:us-east-1:123456789012:db:my-instance-1"]

  jumphost_instance_id = "i-0123456789abcdef0"

  stress_lambda_arns = [
    "arn:aws:lambda:us-east-1:123456789012:function:dev-aurora-stress-cpu_stress",
  ]
  stress_lambda_function_names = {
    cpu_stress            = "dev-aurora-stress-cpu_stress"
    memory_stress         = "dev-aurora-stress-memory_stress"
    connection_exhaustion = "dev-aurora-stress-connection_exhaustion"
  }

  tags = {
    Project = "my-project"
  }
}
```

## Required inputs

- `region`
- `environment`
- `rds_cluster_arn`
- `rds_cluster_identifier`
- `rds_instance_arns`

## Optional highlights

- `enable_*` flags — selectively enable experiment templates
- `redis_*` variables — add Redis/ElastiCache experiments
- `network_latency_*` variables — configure EC2 network latency injection
- `enable_ec2_termination` — enable destructive instance termination experiments

See `variables.tf` for the full input list and `outputs.tf` for emitted experiment IDs.

## Experiment catalog

| Experiment | Type | Enabled by default | Run via output |
|------------|------|--------------------|----------------|
| Aurora cluster failover | Native FIS (`aws:rds:cluster-failover`) | yes | `failover_experiment_id` |
| DB instance reboot | Native FIS (`aws:rds:reboot-db-instances`) | yes | `reboot_experiment_id` |
| Combined failover + wait + reboot | Compound | yes | `combined_experiment_id` |
| Network connectivity loss to DB | Network disruption (SG/ENI deny) | no | `network_disruption_experiment_id` |
| DB AZ power interruption | Compound (disruption + reboot) | no | `az_interruption_experiment_id` |
| EC2 network latency injection | SSM + `AWSFIS-Run-Network-Latency-Sources` (tc netem) | no | `network_latency_experiment_ids` |
| Simple all-traffic network latency | `AWSFIS-Run-Network-Latency` | no | `network_latency_simple_experiment_ids` |
| Aurora CPU stress | SSM on jump host → Lambda | no | `cpu_stress_experiment_id` |
| Aurora memory stress | SSM on jump host → Lambda | no | `memory_stress_experiment_id` |
| Aurora connection exhaustion | SSM on jump host → Lambda | no | `connection_exhaustion_experiment_id` |
| Redis CPU stress | SSM on jump host → Lambda | no | `redis_cpu_stress_experiment_id` |
| Redis memory stress | SSM on jump host → Lambda | no | `redis_memory_stress_experiment_id` |
| Redis connection exhaustion | SSM on jump host → Lambda | no | `redis_connection_exhaustion_experiment_id` |
| Redis replication group failover | SSM on jump host → Lambda (`TestFailover`) | no | `redis_failover_experiment_id` |
| Redis failover under CPU stress | SSM on jump host → Lambda | no | `redis_failover_under_stress_experiment_id` |
| EC2 instance termination | Native FIS (`aws:ec2:terminate-instances`) | no | `ec2_termination_experiment_id` |

Templates not enabled by default are only created when the corresponding
`enable_*` flag is true and any required target ARNs/IDs are supplied. Created
templates are not run until you start the experiment.

## Running an experiment

Experiment template IDs are exposed through the module outputs. Start any
experiment with:

```bash
aws fis start-experiment \
  --experiment-template-id <experiment-id-from-output> \
  --region <region>
```

For example, to run the Aurora cluster failover:

```bash
id=$(terraform output -raw failover_experiment_id)
aws fis start-experiment --experiment-template-id "$id" --region <region>
```

To run a Lambda-backed stress experiment (Aurora CPU stress), first point
`stress_lambda_arns` / `stress_lambda_function_names` at the functions deployed
by the `aurora-fault-injection` module and enable `enable_stress_tests`:

```bash
id=$(terraform output -raw cpu_stress_experiment_id)
aws fis start-experiment --experiment-template-id "$id" --region <region>
```

You can also trigger the stress Lambdas directly without FIS using
`aws lambda invoke` (see the `aurora-fault-injection` and
`elasticache-stress-test` module READMEs).

## Stop conditions

The module creates CloudWatch alarms used by FIS as stop conditions. Review and
tune these per experiment; the defaults are:

**Aurora (RDS)**
- `CPUUtilization` > 95% (average, 2m)
- `FreeableMemory` < ~2 GB (minimum, 2m)
- `DatabaseConnections` > 68 (maximum, 2m) — only when `enable_stress_alarms` is set

**Redis/Valkey (ElastiCache)**
- `EngineCPUUtilization` > 90% (average, 2m)
- `FreeableMemory` < 100 MB (minimum, 2m)
- `CurrConnections` > 64,000 (maximum, 2m)
- `ReplicationLag` > 60 s (maximum, 2m)

The defaults are intentionally conservative. If the target has a higher
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
- The underlying stress Lambdas need the relevant Lambda layers and VPC access
  (see the `aurora-fault-injection`, `elasticache-stress-test` and
  `lambda-layer` module READMEs).

See `outputs.tf` for the emitted experiment template IDs and alarm ARN.