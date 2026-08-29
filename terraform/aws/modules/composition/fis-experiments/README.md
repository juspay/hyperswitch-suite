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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | >= 1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.fis_stop_condition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.fis_stop_connections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.fis_stop_memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.redis_connections_stop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.redis_cpu_stop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.redis_memory_stop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.redis_replica_lag_stop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_fis_experiment_template.aurora_failover](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.combined_failover_reboot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.connection_exhaustion_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.cpu_stress_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.ec2_termination](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.memory_stress_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.network_latency](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.network_latency_simple](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.rds_reboot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.redis_connection_exhaustion_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.redis_cpu_stress_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.redis_failover](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.redis_failover_under_stress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_fis_experiment_template.redis_memory_stress_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template) | resource |
| [aws_iam_role.fis_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.fis_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [awscc_fis_experiment_template.az_power_interruption](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/fis_experiment_template) | resource |
| [awscc_fis_experiment_template.network_disruption](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/fis_experiment_template) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS Account ID | `string` | `""` | no |
| <a name="input_az_interruption_duration"></a> [az\_interruption\_duration](#input\_az\_interruption\_duration) | Duration for AZ power interruption experiment (ISO 8601 format, e.g. PT30M = 30 minutes) | `string` | `"PT30M"` | no |
| <a name="input_ec2_termination_target_instance_arns"></a> [ec2\_termination\_target\_instance\_arns](#input\_ec2\_termination\_target\_instance\_arns) | List of EC2 instance ARNs to terminate. FIS will use the aws:ec2:terminate-instances action. ⚠️ This permanently destroys the instances — only target disposable/test instances. | `list(string)` | `[]` | no |
| <a name="input_enable_az_interruption"></a> [enable\_az\_interruption](#input\_enable\_az\_interruption) | Enable FIS experiment: AZ power interruption (compound) | `bool` | `false` | no |
| <a name="input_enable_combined"></a> [enable\_combined](#input\_enable\_combined) | Enable FIS experiment: Combined failover + wait + reboot | `bool` | `true` | no |
| <a name="input_enable_ec2_termination"></a> [enable\_ec2\_termination](#input\_enable\_ec2\_termination) | Enable FIS experiment: EC2 instance termination via aws:ec2:terminate-instances. ⚠️ Permanently destroys targeted instances. | `bool` | `false` | no |
| <a name="input_enable_failover"></a> [enable\_failover](#input\_enable\_failover) | Enable FIS experiment: Aurora cluster failover | `bool` | `true` | no |
| <a name="input_enable_network_disruption"></a> [enable\_network\_disruption](#input\_enable\_network\_disruption) | Enable FIS experiment: Network connectivity loss to DB | `bool` | `false` | no |
| <a name="input_enable_network_latency"></a> [enable\_network\_latency](#input\_enable\_network\_latency) | Enable FIS experiment: Network latency injection on EC2 instances via aws:ssm:send-command + AWSFIS-Run-Network-Latency-Sources (tc netem) | `bool` | `false` | no |
| <a name="input_enable_network_latency_simple"></a> [enable\_network\_latency\_simple](#input\_enable\_network\_latency\_simple) | Enable FIS experiment: Simple network latency on ALL traffic via AWSFIS-Run-Network-Latency (no source targeting, no jitter) | `bool` | `false` | no |
| <a name="input_enable_reboot"></a> [enable\_reboot](#input\_enable\_reboot) | Enable FIS experiment: DB instance reboot | `bool` | `true` | no |
| <a name="input_enable_redis_failover"></a> [enable\_redis\_failover](#input\_enable\_redis\_failover) | Enable FIS experiment: standalone Redis replication group failover (TestFailover via Lambda invoked through SSM on jump host) | `bool` | `false` | no |
| <a name="input_enable_redis_failover_under_stress"></a> [enable\_redis\_failover\_under\_stress](#input\_enable\_redis\_failover\_under\_stress) | Enable FIS experiment: Redis failover triggered under CPU stress (stress starts → wait 2 minutes → failover while stress continues) | `bool` | `false` | no |
| <a name="input_enable_redis_stress_alarms"></a> [enable\_redis\_stress\_alarms](#input\_enable\_redis\_stress\_alarms) | Enable CloudWatch alarms for Redis stress tests (EngineCPUUtilization > 90%, FreeableMemory < 100MB, CurrConnections > 64000) | `bool` | `false` | no |
| <a name="input_enable_redis_stress_tests"></a> [enable\_redis\_stress\_tests](#input\_enable\_redis\_stress\_tests) | Enable FIS experiments: Redis CPU/memory/connection stress test Lambda invocation via SSM on jump host (ElastiCache) | `bool` | `false` | no |
| <a name="input_enable_stress_alarms"></a> [enable\_stress\_alarms](#input\_enable\_stress\_alarms) | Enable additional CloudWatch alarms for stress tests (FreeableMemory < 2GB, DatabaseConnections > 68) | `bool` | `false` | no |
| <a name="input_enable_stress_tests"></a> [enable\_stress\_tests](#input\_enable\_stress\_tests) | Enable FIS experiments: CPU/memory/connection stress test Lambda invocation via SM on jump host (RDS Aurora) | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, prod) | `string` | n/a | yes |
| <a name="input_fis_role_name"></a> [fis\_role\_name](#input\_fis\_role\_name) | Base name of the IAM role for FIS experiment execution | `string` | `"FISExperimentRole"` | no |
| <a name="input_jumphost_instance_id"></a> [jumphost\_instance\_id](#input\_jumphost\_instance\_id) | EC2 instance ID of the jump host used to invoke stress test Lambda functions via SSM. Leave empty to skip stress test templates. | `string` | `""` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key ARN used by the RDS cluster for storage encryption. FIS needs kms:Decrypt/Encrypt to reboot/failover encrypted clusters. Leave empty to allow all keys. | `string` | `""` | no |
| <a name="input_network_disruption_duration"></a> [network\_disruption\_duration](#input\_network\_disruption\_duration) | Duration for network disruption experiment (ISO 8601 format, e.g. PT3M = 3 minutes) | `string` | `"PT3M"` | no |
| <a name="input_network_latency_delay_ms"></a> [network\_latency\_delay\_ms](#input\_network\_latency\_delay\_ms) | Network latency to inject in milliseconds | `number` | `200` | no |
| <a name="input_network_latency_duration"></a> [network\_latency\_duration](#input\_network\_latency\_duration) | FIS action duration (ISO 8601, e.g. PT5M = 5 minutes). Must be >= network\_latency\_duration\_seconds. | `string` | `"PT5M"` | no |
| <a name="input_network_latency_duration_seconds"></a> [network\_latency\_duration\_seconds](#input\_network\_latency\_duration\_seconds) | SSM document DurationSeconds — how long the tc netem delay rule stays active on the instance (in seconds). Must be <= FIS action duration in seconds. | `number` | `300` | no |
| <a name="input_network_latency_flows_percent"></a> [network\_latency\_flows\_percent](#input\_network\_latency\_flows\_percent) | Percentage of network flows to affect (1-100) | `number` | `100` | no |
| <a name="input_network_latency_install_dependencies"></a> [network\_latency\_install\_dependencies](#input\_network\_latency\_install\_dependencies) | Whether to install tc/netem dependencies via SSM. Set to false if dependencies are already baked into the AMI (e.g. custom FIS AMI) or instances are in private subnet without package repo access. | `bool` | `true` | no |
| <a name="input_network_latency_interface"></a> [network\_latency\_interface](#input\_network\_latency\_interface) | Network interface to target: DEFAULT (primary interface), ALL (all interfaces), or specific name (e.g. eth0) | `string` | `"DEFAULT"` | no |
| <a name="input_network_latency_jitter_ms"></a> [network\_latency\_jitter\_ms](#input\_network\_latency\_jitter\_ms) | Jitter to inject in milliseconds (added on top of delay, normal distribution) | `number` | `10` | no |
| <a name="input_network_latency_simple_delay_ms"></a> [network\_latency\_simple\_delay\_ms](#input\_network\_latency\_simple\_delay\_ms) | Network latency to inject in milliseconds for the simple all-traffic variant (no source targeting, no jitter) | `number` | `200` | no |
| <a name="input_network_latency_simple_interface"></a> [network\_latency\_simple\_interface](#input\_network\_latency\_simple\_interface) | Network interface for simple latency: eth0, eth1, etc. Default is eth0 (primary) | `string` | `"eth0"` | no |
| <a name="input_network_latency_simple_sources"></a> [network\_latency\_simple\_sources](#input\_network\_latency\_simple\_sources) | Comma-separated sources for simple latency. Default ALL = all traffic. Set to specific IPs/CIDRs/domains/AZs to target only that traffic. Uses AWSFIS-Run-Network-Latency-Sources SSM document. | `string` | `"ALL"` | no |
| <a name="input_network_latency_sources"></a> [network\_latency\_sources](#input\_network\_latency\_sources) | Comma-separated list of sources to apply latency to. Values: IPv4 address, CIDR block, domain name, AZ name (e.g. ap-south-1a), AZ ID, ALL, DYNAMODB, S3. No spaces after commas. | `string` | `"ALL"` | no |
| <a name="input_network_latency_target_environment_tag"></a> [network\_latency\_target\_environment\_tag](#input\_network\_latency\_target\_environment\_tag) | Value of the Environment tag used to filter network latency targets. Defaults to var.environment. Set to environment.short if your live instances use the short environment code (e.g., sbx). | `string` | `""` | no |
| <a name="input_network_latency_target_instance_arns"></a> [network\_latency\_target\_instance\_arns](#input\_network\_latency\_target\_instance\_arns) | List of EC2 instance ARNs to target for network latency injection. Used when network\_latency\_target\_resource\_tags is empty. FIS will run the AWSFIS-Run-Network-Latency-Sources SSM document on these instances via aws:ssm:send-command. | `list(string)` | `[]` | no |
| <a name="input_network_latency_target_resource_tags"></a> [network\_latency\_target\_resource\_tags](#input\_network\_latency\_target\_resource\_tags) | Map of tags to select EC2 instances for network latency injection (e.g., {Service="envoy-proxy", Environment="dev"}). When non-empty, takes precedence over network\_latency\_target\_instance\_arns. FIS resolves targets at experiment start time, so instances can be replaced without re-applying. | `map(string)` | `{}` | no |
| <a name="input_network_latency_target_service_names"></a> [network\_latency\_target\_service\_names](#input\_network\_latency\_target\_service\_names) | List of EC2 Service tag values to target for network latency injection (e.g., ["envoy-proxy", "locker"]). Uses FIS filters so multiple values are OR-ed. Takes precedence over instance ARNs and resource\_tags. | `list(string)` | `[]` | no |
| <a name="input_network_latency_traffic_type"></a> [network\_latency\_traffic\_type](#input\_network\_latency\_traffic\_type) | Traffic type to apply latency to: ingress or egress | `string` | `"egress"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | `""` | no |
| <a name="input_rds_cluster_arn"></a> [rds\_cluster\_arn](#input\_rds\_cluster\_arn) | ARN of the RDS Aurora cluster to target for failover experiments | `string` | n/a | yes |
| <a name="input_rds_cluster_identifier"></a> [rds\_cluster\_identifier](#input\_rds\_cluster\_identifier) | Identifier of the RDS Aurora cluster (used for CloudWatch alarm dimension) | `string` | n/a | yes |
| <a name="input_rds_instance_arns"></a> [rds\_instance\_arns](#input\_rds\_instance\_arns) | List of RDS DB instance ARNs to target for reboot experiments | `list(string)` | n/a | yes |
| <a name="input_rds_security_group_id"></a> [rds\_security\_group\_id](#input\_rds\_security\_group\_id) | Security group ID of the test DB instance. Used to filter only the DB's ENIs for network disruption (not all ENIs in the subnet) | `string` | `""` | no |
| <a name="input_redis_cluster_id"></a> [redis\_cluster\_id](#input\_redis\_cluster\_id) | Elasticache CacheClusterId (per-node cluster ID, NOT replication group ID) for Redis stress test CloudWatch alarm dimensions. E.g., sbx-test-redis-0001-001. Leave empty to skip Redis stress alarms. | `string` | `""` | no |
| <a name="input_redis_failover_lambda_function_arn"></a> [redis\_failover\_lambda\_function\_arn](#input\_redis\_failover\_lambda\_function\_arn) | ARN of the Lambda function that triggers ElastiCache TestFailover. Used for FIS execution role IAM permissions (lambda:InvokeFunction). | `string` | `""` | no |
| <a name="input_redis_failover_lambda_function_name"></a> [redis\_failover\_lambda\_function\_name](#input\_redis\_failover\_lambda\_function\_name) | Name of the Lambda function that triggers ElastiCache TestFailover for the Redis replication group. Invoked via SSM on the jump host. | `string` | `""` | no |
| <a name="input_redis_node_group_id"></a> [redis\_node\_group\_id](#input\_redis\_node\_group\_id) | ElastiCache Redis node group ID (shard number) for the replication group, used as a dimension for the ReplicationLag stop-condition alarm. E.g., 0001 | `string` | `"0001"` | no |
| <a name="input_redis_replication_group_id"></a> [redis\_replication\_group\_id](#input\_redis\_replication\_group\_id) | ElastiCache Redis replication group ID for failover experiments and replica-lag alarm dimension (e.g., sbx-test-redis). Leave empty to skip the replica-lag stop-condition alarm. | `string` | `""` | no |
| <a name="input_redis_stress_lambda_arns"></a> [redis\_stress\_lambda\_arns](#input\_redis\_stress\_lambda\_arns) | List of Lambda function ARNs for Redis stress testing. Used for IAM permissions. Leave empty to skip Redis stress test templates. | `list(string)` | `[]` | no |
| <a name="input_redis_stress_lambda_function_names"></a> [redis\_stress\_lambda\_function\_names](#input\_redis\_stress\_lambda\_function\_names) | Map of Redis stress type to Lambda function name. Keys must be: cpu\_stress, memory\_stress, connection\_exhaustion | `map(string)` | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_stress_duration_seconds"></a> [stress\_duration\_seconds](#input\_stress\_duration\_seconds) | Duration for stress test experiments in seconds (used to calculate FIS action duration) | `number` | `300` | no |
| <a name="input_stress_lambda_arns"></a> [stress\_lambda\_arns](#input\_stress\_lambda\_arns) | List of Lambda function ARNs for stress testing. Used for IAM permissions. Leave empty to skip stress test templates. | `list(string)` | `[]` | no |
| <a name="input_stress_lambda_function_names"></a> [stress\_lambda\_function\_names](#input\_stress\_lambda\_function\_names) | Map of stress type to Lambda function name. Keys must be: cpu\_stress, memory\_stress, connection\_exhaustion | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_target_az"></a> [target\_az](#input\_target\_az) | Target availability zone for AZ power interruption experiment (e.g. ap-south-1a) | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_az_interruption_experiment_id"></a> [az\_interruption\_experiment\_id](#output\_az\_interruption\_experiment\_id) | ID of the AZ power interruption experiment template |
| <a name="output_combined_experiment_id"></a> [combined\_experiment\_id](#output\_combined\_experiment\_id) | ID of the combined failover + wait + reboot experiment template |
| <a name="output_connection_exhaustion_experiment_id"></a> [connection\_exhaustion\_experiment\_id](#output\_connection\_exhaustion\_experiment\_id) | ID of the connection exhaustion Lambda experiment template |
| <a name="output_cpu_stress_experiment_id"></a> [cpu\_stress\_experiment\_id](#output\_cpu\_stress\_experiment\_id) | ID of the CPU stress Lambda experiment template |
| <a name="output_ec2_termination_experiment_id"></a> [ec2\_termination\_experiment\_id](#output\_ec2\_termination\_experiment\_id) | ID of the EC2 instance termination experiment template |
| <a name="output_failover_experiment_id"></a> [failover\_experiment\_id](#output\_failover\_experiment\_id) | ID of the Aurora failover experiment template |
| <a name="output_fis_role_arn"></a> [fis\_role\_arn](#output\_fis\_role\_arn) | ARN of the FIS IAM role |
| <a name="output_fis_role_name"></a> [fis\_role\_name](#output\_fis\_role\_name) | Name of the FIS IAM role |
| <a name="output_memory_stress_experiment_id"></a> [memory\_stress\_experiment\_id](#output\_memory\_stress\_experiment\_id) | ID of the memory stress Lambda experiment template |
| <a name="output_network_disruption_experiment_id"></a> [network\_disruption\_experiment\_id](#output\_network\_disruption\_experiment\_id) | ID of the network connectivity loss experiment template |
| <a name="output_network_latency_experiment_ids"></a> [network\_latency\_experiment\_ids](#output\_network\_latency\_experiment\_ids) | Map of network latency injection experiment template IDs keyed by target (Service name or default) |
| <a name="output_network_latency_simple_experiment_ids"></a> [network\_latency\_simple\_experiment\_ids](#output\_network\_latency\_simple\_experiment\_ids) | Map of simple network latency (all traffic) experiment template IDs keyed by target (Service name or default) |
| <a name="output_reboot_experiment_id"></a> [reboot\_experiment\_id](#output\_reboot\_experiment\_id) | ID of the RDS reboot experiment template |
| <a name="output_redis_connection_exhaustion_experiment_id"></a> [redis\_connection\_exhaustion\_experiment\_id](#output\_redis\_connection\_exhaustion\_experiment\_id) | ID of the Redis connection exhaustion Lambda experiment template |
| <a name="output_redis_cpu_stress_experiment_id"></a> [redis\_cpu\_stress\_experiment\_id](#output\_redis\_cpu\_stress\_experiment\_id) | ID of the Redis CPU stress Lambda experiment template |
| <a name="output_redis_failover_experiment_id"></a> [redis\_failover\_experiment\_id](#output\_redis\_failover\_experiment\_id) | ID of the Redis replication group failover (standalone) experiment template |
| <a name="output_redis_failover_under_stress_experiment_id"></a> [redis\_failover\_under\_stress\_experiment\_id](#output\_redis\_failover\_under\_stress\_experiment\_id) | ID of the Redis failover under CPU stress experiment template |
| <a name="output_redis_memory_stress_experiment_id"></a> [redis\_memory\_stress\_experiment\_id](#output\_redis\_memory\_stress\_experiment\_id) | ID of the Redis memory stress Lambda experiment template |
| <a name="output_stop_condition_alarm_arn"></a> [stop\_condition\_alarm\_arn](#output\_stop\_condition\_alarm\_arn) | ARN of the CloudWatch alarm used as the stop condition |
<!-- END_TF_DOCS -->