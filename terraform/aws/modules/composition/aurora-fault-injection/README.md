# Aurora Fault Injection & Stress Test Module

Generic Terraform module that deploys Lambda-based fault injection and stress tests for Amazon Aurora PostgreSQL.

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

See `variables.tf` for the full input list and `outputs.tf` for emitted ARNs and experiment IDs.
