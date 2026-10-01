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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
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
| [aws_cloudwatch_log_group.fault_injection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.stress_test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.secrets_and_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lambda_function.fault_injection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.stress_test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_secretsmanager_secret.db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.db_ingress_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [archive_file.fault_injection_code](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.stress_test_code](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_secretsmanager_secret.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_conn_batch_size"></a> [conn\_batch\_size](#input\_conn\_batch\_size) | Connections per thread per batch in connection exhaustion test | `number` | `30` | no |
| <a name="input_conn_hold_seconds"></a> [conn\_hold\_seconds](#input\_conn\_hold\_seconds) | Seconds to hold connections before closing in connection exhaustion test | `number` | `5` | no |
| <a name="input_conn_phase_threads"></a> [conn\_phase\_threads](#input\_conn\_phase\_threads) | Comma-separated cumulative thread counts per connection exhaustion phase (e.g. 20,40,56) | `string` | `"20,40,56"` | no |
| <a name="input_conn_ramp_seconds"></a> [conn\_ramp\_seconds](#input\_conn\_ramp\_seconds) | Seconds over which each worker spreads its connection openings to avoid a steep spike | `number` | `60` | no |
| <a name="input_cpu_phase_baseline_pct"></a> [cpu\_phase\_baseline\_pct](#input\_cpu\_phase\_baseline\_pct) | Estimated CPU percentage consumed by the TPC-B workload alone. When cpu\_phase\_targets is set, the boost is computed as target - baseline. | `number` | `87` | no |
| <a name="input_cpu_phase_duty"></a> [cpu\_phase\_duty](#input\_cpu\_phase\_duty) | Comma-separated duty cycles per CPU stress phase (e.g. 0.6,0.8,1.0) | `string` | `"0.6,0.8,1.0"` | no |
| <a name="input_cpu_phase_extra_threads"></a> [cpu\_phase\_extra\_threads](#input\_cpu\_phase\_extra\_threads) | Comma-separated extra pure-CPU worker threads per phase, added on top of TPC-B and target-boost workers (e.g. 0,1,3). | `string` | `"0,0,0"` | no |
| <a name="input_cpu_phase_pure_cpu"></a> [cpu\_phase\_pure\_cpu](#input\_cpu\_phase\_pure\_cpu) | Comma-separated booleans per CPU stress phase. When true, the phase uses a read-only generate\_series CPU-burn query instead of TPC-B writes (e.g. false,false,true) | `string` | `"false,false,true"` | no |
| <a name="input_cpu_phase_targets"></a> [cpu\_phase\_targets](#input\_cpu\_phase\_targets) | Comma-separated target CPU percentages per phase. When set, active connection count is used instead of threads/duty (e.g. 70,75,80). Formula: effective\_connections = target\_pct/100 * cpu\_vcpus. | `string` | `""` | no |
| <a name="input_cpu_phase_threads"></a> [cpu\_phase\_threads](#input\_cpu\_phase\_threads) | Comma-separated thread count per CPU stress phase (e.g. 2,2,16) | `string` | `"2,2,16"` | no |
| <a name="input_cpu_pure_cpu_queries_per_loop"></a> [cpu\_pure\_cpu\_queries\_per\_loop](#input\_cpu\_pure\_cpu\_queries\_per\_loop) | Number of pure-CPU queries to issue back-to-back before duty-cycle sleep. Higher values keep the CPU pipeline fuller. | `number` | `10` | no |
| <a name="input_cpu_pure_cpu_series_count"></a> [cpu\_pure\_cpu\_series\_count](#input\_cpu\_pure\_cpu\_series\_count) | Number of rows for the pure-CPU generate\_series query in pure\_cpu phases. Smaller rows with more queries per loop keeps the DB pipeline full. | `number` | `1000000` | no |
| <a name="input_cpu_vcpus"></a> [cpu\_vcpus](#input\_cpu\_vcpus) | Number of vCPUs on the Aurora instance. Used to compute active connection count when cpu\_phase\_targets is set. | `number` | `4` | no |
| <a name="input_create_secret"></a> [create\_secret](#input\_create\_secret) | Create a new Secrets Manager secret. If false, looks up an existing secret by secret\_name. The existing secret must contain JSON with: username, password, host, port, dbname | `bool` | `true` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Create a dedicated security group for Lambda. If false, provide lambda\_security\_group\_id (e.g., reuse jump host SG) | `bool` | `false` | no |
| <a name="input_db_endpoint"></a> [db\_endpoint](#input\_db\_endpoint) | Aurora PostgreSQL writer endpoint (cluster endpoint) | `string` | n/a | yes |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Database name | `string` | `"postgres"` | no |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | Master database password (will be stored in Secrets Manager, KMS-encrypted) | `string` | n/a | yes |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | Database port | `number` | `5432` | no |
| <a name="input_db_security_group_id"></a> [db\_security\_group\_id](#input\_db\_security\_group\_id) | Database security group ID (required when create\_security\_group = true, to add ingress rule for port 5432) | `string` | `""` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Master database username | `string` | `"postgres"` | no |
| <a name="input_enable_stress_tests"></a> [enable\_stress\_tests](#input\_enable\_stress\_tests) | Deploy stress test Lambda functions (cpu\_stress, memory\_stress, connection\_exhaustion) | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment short name for resource naming (e.g., sbx, prod) | `string` | n/a | yes |
| <a name="input_kms_key_alias"></a> [kms\_key\_alias](#input\_kms\_key\_alias) | Alias for the KMS key used to encrypt Secrets Manager secret | `string` | `""` | no |
| <a name="input_lambda_layers"></a> [lambda\_layers](#input\_lambda\_layers) | List of Lambda layer ARNs (e.g., existing psycopg2-python311 layer) | `list(string)` | `[]` | no |
| <a name="input_lambda_memory_size"></a> [lambda\_memory\_size](#input\_lambda\_memory\_size) | Lambda memory size in MB | `number` | `256` | no |
| <a name="input_lambda_runtime"></a> [lambda\_runtime](#input\_lambda\_runtime) | Lambda runtime (must match compatible\_runtimes of the psycopg2 layer) | `string` | `"python3.11"` | no |
| <a name="input_lambda_security_group_id"></a> [lambda\_security\_group\_id](#input\_lambda\_security\_group\_id) | Existing security group ID for Lambda (required when create\_security\_group = false). E.g., jump host internal SG | `string` | `""` | no |
| <a name="input_lambda_subnet_ids"></a> [lambda\_subnet\_ids](#input\_lambda\_subnet\_ids) | List of subnet IDs for Lambda VPC config (use lambda subnets, not DB subnets) | `list(string)` | n/a | yes |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Lambda timeout in seconds | `number` | `30` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log group retention in days | `number` | `14` | no |
| <a name="input_mem_agg_rows_max"></a> [mem\_agg\_rows\_max](#input\_mem\_agg\_rows\_max) | Maximum array\_agg rows per worker. Raise to build larger in-memory arrays. | `number` | `20000000` | no |
| <a name="input_mem_arrays_per_worker"></a> [mem\_arrays\_per\_worker](#input\_mem\_arrays\_per\_worker) | Number of large arrays each worker holds simultaneously. Higher values consume memory faster. | `number` | `3` | no |
| <a name="input_mem_phase_agg_rows"></a> [mem\_phase\_agg\_rows](#input\_mem\_phase\_agg\_rows) | Comma-separated array\_agg row counts per memory stress phase (e.g. 5000000,10000000,20000000) | `string` | `"5000000,10000000,20000000"` | no |
| <a name="input_mem_phase_durations"></a> [mem\_phase\_durations](#input\_mem\_phase\_durations) | Comma-separated memory stress phase durations in seconds. Defaults to PHASE\_DURATIONS if unset. | `string` | `""` | no |
| <a name="input_mem_phase_idle"></a> [mem\_phase\_idle](#input\_mem\_phase\_idle) | Comma-separated cumulative idle connection counts per memory stress phase (e.g. 50,150,300) | `string` | `"50,150,300"` | no |
| <a name="input_mem_phase_sort"></a> [mem\_phase\_sort](#input\_mem\_phase\_sort) | Comma-separated cumulative sort session counts per memory stress phase (e.g. 5,10,20) | `string` | `"5,10,20"` | no |
| <a name="input_mem_phase_temp_mb"></a> [mem\_phase\_temp\_mb](#input\_mem\_phase\_temp\_mb) | Comma-separated temp\_buffers MB per memory stress phase (e.g. 256,512,1024) | `string` | `"256,512,1024"` | no |
| <a name="input_mem_temp_rows_max"></a> [mem\_temp\_rows\_max](#input\_mem\_temp\_rows\_max) | Maximum rows per temp table worker. Larger temp tables consume more temp\_buffers memory. | `number` | `5000000` | no |
| <a name="input_mem_work_mem_mb"></a> [mem\_work\_mem\_mb](#input\_mem\_work\_mem\_mb) | work\_mem in MB for each memory stress worker session. Higher values force more in-memory operations and pressure shared resources. | `number` | `512` | no |
| <a name="input_phase_durations"></a> [phase\_durations](#input\_phase\_durations) | Comma-separated phase durations in seconds (e.g. 240,300,300 = 4min+5min+5min) | `string` | `"240,300,300"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | Name of the Secrets Manager secret for DB credentials | `string` | `""` | no |
| <a name="input_sort_connections"></a> [sort\_connections](#input\_sort\_connections) | Number of concurrent sort connections for memory stress test | `number` | `10` | no |
| <a name="input_sort_rows"></a> [sort\_rows](#input\_sort\_rows) | Number of rows to generate and sort in each memory stress iteration | `number` | `10000000` | no |
| <a name="input_sort_work_mem_mb"></a> [sort\_work\_mem\_mb](#input\_sort\_work\_mem\_mb) | work\_mem setting in MB for each sort connection in memory stress test | `number` | `512` | no |
| <a name="input_stress_clients"></a> [stress\_clients](#input\_stress\_clients) | Default number of concurrent clients/connections for stress tests | `number` | `50` | no |
| <a name="input_stress_duration"></a> [stress\_duration](#input\_stress\_duration) | Default stress test duration in seconds | `number` | `300` | no |
| <a name="input_stress_lambda_memory_size"></a> [stress\_lambda\_memory\_size](#input\_stress\_lambda\_memory\_size) | Lambda memory size in MB for stress test functions | `number` | `512` | no |
| <a name="input_stress_lambda_timeout"></a> [stress\_lambda\_timeout](#input\_stress\_lambda\_timeout) | Lambda timeout in seconds for stress test functions (max 900) | `number` | `900` | no |
| <a name="input_stress_threads"></a> [stress\_threads](#input\_stress\_threads) | Default number of worker threads for stress tests | `number` | `4` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where Lambda functions will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_invoke_commands"></a> [invoke\_commands](#output\_invoke\_commands) | AWS CLI commands to invoke each fault injection Lambda function |
| <a name="output_kms_key_alias"></a> [kms\_key\_alias](#output\_kms\_key\_alias) | Alias of the KMS key |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the KMS key used for Secrets Manager encryption |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ID of the KMS key |
| <a name="output_lambda_function_arns"></a> [lambda\_function\_arns](#output\_lambda\_function\_arns) | Map of fault type to Lambda function ARN |
| <a name="output_lambda_function_names"></a> [lambda\_function\_names](#output\_lambda\_function\_names) | Map of fault type to Lambda function name |
| <a name="output_lambda_iam_role_arn"></a> [lambda\_iam\_role\_arn](#output\_lambda\_iam\_role\_arn) | ARN of the Lambda IAM role |
| <a name="output_lambda_layers"></a> [lambda\_layers](#output\_lambda\_layers) | Lambda layer ARNs used by the fault injection functions |
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | ARN of the Secrets Manager secret containing DB credentials |
| <a name="output_secret_name"></a> [secret\_name](#output\_secret\_name) | Name of the Secrets Manager secret |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group ID used by Lambda functions (created or reused) |
| <a name="output_stress_test_function_arns"></a> [stress\_test\_function\_arns](#output\_stress\_test\_function\_arns) | Map of stress type to Lambda function ARN |
| <a name="output_stress_test_function_names"></a> [stress\_test\_function\_names](#output\_stress\_test\_function\_names) | Map of stress type to Lambda function name |
| <a name="output_stress_test_invoke_commands"></a> [stress\_test\_invoke\_commands](#output\_stress\_test\_invoke\_commands) | AWS CLI commands to invoke each stress test Lambda function |
<!-- END_TF_DOCS -->