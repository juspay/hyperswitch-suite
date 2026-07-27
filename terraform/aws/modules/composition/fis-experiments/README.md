# AWS FIS Chaos Experiments Module

Generic Terraform module that creates AWS Fault Injection Service (FIS) experiment templates for RDS Aurora, ElastiCache Redis/Valkey, EC2, and network paths.

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
