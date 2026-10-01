# ============================================================================
# FIS Experiments Module - Variables
# ============================================================================

variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sandbox, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = ""
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = ""
}

# ============================================================================
# FIS IAM Role
# ============================================================================

variable "fis_role_name" {
  description = "Base name of the IAM role for FIS experiment execution"
  type        = string
  default     = "FISExperimentRole"
}

# ============================================================================
# RDS Target Resources
# ============================================================================

variable "rds_cluster_arn" {
  description = "ARN of the RDS Aurora cluster to target for failover experiments"
  type        = string
}

variable "rds_cluster_identifier" {
  description = "Identifier of the RDS Aurora cluster (used for CloudWatch alarm dimension)"
  type        = string
}

variable "rds_instance_arns" {
  description = "List of RDS DB instance ARNs to target for reboot experiments"
  type        = list(string)
}

# ============================================================================
# KMS Key (for encrypted RDS clusters)
# ============================================================================

variable "kms_key_arn" {
  description = "KMS key ARN used by the RDS cluster for storage encryption. FIS needs kms:Decrypt/Encrypt to reboot/failover encrypted clusters. Leave empty to allow all keys."
  type        = string
  default     = ""
}

# ============================================================================
# Tags
# ============================================================================

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Network Disruption Experiment
# ============================================================================

variable "rds_security_group_id" {
  description = "Security group ID of the test DB instance. Used to filter only the DB's ENIs for network disruption (not all ENIs in the subnet)"
  type        = string
  default     = ""
}

variable "network_disruption_duration" {
  description = "Duration for network disruption experiment (ISO 8601 format, e.g. PT3M = 3 minutes)"
  type        = string
  default     = "PT3M"
}

# ============================================================================
# Network Latency Injection Experiment (EC2)
# ============================================================================

variable "network_latency_target_instance_arns" {
  description = "List of EC2 instance ARNs to target for network latency injection. Used when network_latency_target_resource_tags is empty. FIS will run the AWSFIS-Run-Network-Latency-Sources SSM document on these instances via aws:ssm:send-command."
  type        = list(string)
  default     = []
}

variable "network_latency_target_resource_tags" {
  description = "Map of tags to select EC2 instances for network latency injection (e.g., {Service=\"envoy-proxy\", Environment=\"dev\"}). When non-empty, takes precedence over network_latency_target_instance_arns. FIS resolves targets at experiment start time, so instances can be replaced without re-applying."
  type        = map(string)
  default     = {}
}

variable "network_latency_target_service_names" {
  description = "List of EC2 Service tag values to target for network latency injection (e.g., [\"envoy-proxy\", \"locker\"]). Uses FIS filters so multiple values are OR-ed. Takes precedence over instance ARNs and resource_tags."
  type        = list(string)
  default     = []
}

variable "network_latency_target_environment_tag" {
  description = "Value of the Environment tag used to filter network latency targets. Defaults to var.environment. Set to environment.short if your live instances use the short environment code (e.g., sbx)."
  type        = string
  default     = ""
}

variable "network_latency_duration" {
  description = "FIS action duration (ISO 8601, e.g. PT5M = 5 minutes). Must be >= network_latency_duration_seconds."
  type        = string
  default     = "PT5M"
}

variable "network_latency_duration_seconds" {
  description = "SSM document DurationSeconds — how long the tc netem delay rule stays active on the instance (in seconds). Must be <= FIS action duration in seconds."
  type        = number
  default     = 300
}

variable "network_latency_delay_ms" {
  description = "Network latency to inject in milliseconds"
  type        = number
  default     = 200
}

variable "network_latency_jitter_ms" {
  description = "Jitter to inject in milliseconds (added on top of delay, normal distribution)"
  type        = number
  default     = 10
}

variable "network_latency_sources" {
  description = "Comma-separated list of sources to apply latency to. Values: IPv4 address, CIDR block, domain name, AZ name (e.g. ap-south-1a), AZ ID, ALL, DYNAMODB, S3. No spaces after commas."
  type        = string
  default     = "ALL"
}

variable "network_latency_interface" {
  description = "Network interface to target: DEFAULT (primary interface), ALL (all interfaces), or specific name (e.g. eth0)"
  type        = string
  default     = "DEFAULT"
}

variable "network_latency_traffic_type" {
  description = "Traffic type to apply latency to: ingress or egress"
  type        = string
  default     = "egress"
}

variable "network_latency_flows_percent" {
  description = "Percentage of network flows to affect (1-100)"
  type        = number
  default     = 100
}

# ============================================================================
# Network Latency Simple (All Traffic) Experiment (EC2)
# ============================================================================

variable "network_latency_install_dependencies" {
  description = "Whether to install tc/netem dependencies via SSM. Set to false if dependencies are already baked into the AMI (e.g. custom FIS AMI) or instances are in private subnet without package repo access."
  type        = bool
  default     = true
}

variable "network_latency_simple_delay_ms" {
  description = "Network latency to inject in milliseconds for the simple all-traffic variant (no source targeting, no jitter)"
  type        = number
  default     = 200
}

variable "network_latency_simple_interface" {
  description = "Network interface for simple latency: eth0, eth1, etc. Default is eth0 (primary)"
  type        = string
  default     = "eth0"
}

variable "network_latency_simple_sources" {
  description = "Comma-separated sources for simple latency. Default ALL = all traffic. Set to specific IPs/CIDRs/domains/AZs to target only that traffic. Uses AWSFIS-Run-Network-Latency-Sources SSM document."
  type        = string
  default     = "ALL"
}

# ============================================================================
# EC2 Instance Termination Experiment
# ============================================================================

variable "ec2_termination_target_instance_arns" {
  description = "List of EC2 instance ARNs to terminate. FIS will use the aws:ec2:terminate-instances action. ⚠️ This permanently destroys the instances — only target disposable/test instances."
  type        = list(string)
  default     = []
}

# ============================================================================
# AZ Power Interruption Experiment
# ============================================================================

variable "target_az" {
  description = "Target availability zone for AZ power interruption experiment (e.g. ap-south-1a)"
  type        = string
  default     = ""
}

variable "az_interruption_duration" {
  description = "Duration for AZ power interruption experiment (ISO 8601 format, e.g. PT30M = 30 minutes)"
  type        = string
  default     = "PT30M"
}

# ============================================================================
# Stress Test Experiments (CPU/Memory/Connection via Lambda)
# ============================================================================

variable "jumphost_instance_id" {
  description = "EC2 instance ID of the jump host used to invoke stress test Lambda functions via SSM. Leave empty to skip stress test templates."
  type        = string
  default     = ""
}

variable "stress_lambda_arns" {
  description = "List of Lambda function ARNs for stress testing. Used for IAM permissions. Leave empty to skip stress test templates."
  type        = list(string)
  default     = []
}

variable "stress_lambda_function_names" {
  description = "Map of stress type to Lambda function name. Keys must be: cpu_stress, memory_stress, connection_exhaustion"
  type        = map(string)
  default     = {}
}

variable "stress_duration_seconds" {
  description = "Duration for stress test experiments in seconds (used to calculate FIS action duration)"
  type        = number
  default     = 300
}

variable "enable_stress_alarms" {
  description = "Enable additional CloudWatch alarms for stress tests (FreeableMemory < 2GB, DatabaseConnections > 68)"
  type        = bool
  default     = false
}

# ============================================================================
# Redis/Elasticache Stress Test Experiments
# ============================================================================

variable "redis_cluster_id" {
  description = "Elasticache CacheClusterId (per-node cluster ID, NOT replication group ID) for Redis stress test CloudWatch alarm dimensions. E.g., sbx-test-redis-0001-001. Leave empty to skip Redis stress alarms."
  type        = string
  default     = ""
}

variable "redis_stress_lambda_arns" {
  description = "List of Lambda function ARNs for Redis stress testing. Used for IAM permissions. Leave empty to skip Redis stress test templates."
  type        = list(string)
  default     = []
}

variable "redis_stress_lambda_function_names" {
  description = "Map of Redis stress type to Lambda function name. Keys must be: cpu_stress, memory_stress, connection_exhaustion"
  type        = map(string)
  default     = {}
}

variable "enable_redis_stress_alarms" {
  description = "Enable CloudWatch alarms for Redis stress tests (EngineCPUUtilization > 90%, FreeableMemory < 100MB, CurrConnections > 64000)"
  type        = bool
  default     = false
}

# ============================================================================
# Redis/ElastiCache Failover Experiments
# ============================================================================

variable "redis_replication_group_id" {
  description = "ElastiCache Redis replication group ID for failover experiments and replica-lag alarm dimension (e.g., sbx-test-redis). Leave empty to skip the replica-lag stop-condition alarm."
  type        = string
  default     = ""
}

variable "redis_node_group_id" {
  description = "ElastiCache Redis node group ID (shard number) for the replication group, used as a dimension for the ReplicationLag stop-condition alarm. E.g., 0001"
  type        = string
  default     = "0001"
}

variable "redis_failover_lambda_function_name" {
  description = "Name of the Lambda function that triggers ElastiCache TestFailover for the Redis replication group. Invoked via SSM on the jump host."
  type        = string
  default     = ""
}

variable "redis_failover_lambda_function_arn" {
  description = "ARN of the Lambda function that triggers ElastiCache TestFailover. Used for FIS execution role IAM permissions (lambda:InvokeFunction)."
  type        = string
  default     = ""
}

# ============================================================================
# Experiment Toggles
# ============================================================================

variable "enable_failover" {
  description = "Enable FIS experiment: Aurora cluster failover"
  type        = bool
  default     = true
}

variable "enable_reboot" {
  description = "Enable FIS experiment: DB instance reboot"
  type        = bool
  default     = true
}

variable "enable_combined" {
  description = "Enable FIS experiment: Combined failover + wait + reboot"
  type        = bool
  default     = true
}

variable "enable_network_disruption" {
  description = "Enable FIS experiment: Network connectivity loss to DB"
  type        = bool
  default     = false
}

variable "enable_az_interruption" {
  description = "Enable FIS experiment: AZ power interruption (compound)"
  type        = bool
  default     = false
}

variable "enable_redis_failover" {
  description = "Enable FIS experiment: standalone Redis replication group failover (TestFailover via Lambda invoked through SSM on jump host)"
  type        = bool
  default     = false
}

variable "enable_redis_failover_under_stress" {
  description = "Enable FIS experiment: Redis failover triggered under CPU stress (stress starts → wait 2 minutes → failover while stress continues)"
  type        = bool
  default     = false
}

variable "enable_network_latency" {
  description = "Enable FIS experiment: Network latency injection on EC2 instances via aws:ssm:send-command + AWSFIS-Run-Network-Latency-Sources (tc netem)"
  type        = bool
  default     = false
}

variable "enable_network_latency_simple" {
  description = "Enable FIS experiment: Simple network latency on ALL traffic via AWSFIS-Run-Network-Latency (no source targeting, no jitter)"
  type        = bool
  default     = false
}

variable "enable_ec2_termination" {
  description = "Enable FIS experiment: EC2 instance termination via aws:ec2:terminate-instances. ⚠️ Permanently destroys targeted instances."
  type        = bool
  default     = false
}

variable "enable_stress_tests" {
  description = "Enable FIS experiments: CPU/memory/connection stress test Lambda invocation via SM on jump host (RDS Aurora)"
  type        = bool
  default     = false
}

variable "enable_redis_stress_tests" {
  description = "Enable FIS experiments: Redis CPU/memory/connection stress test Lambda invocation via SSM on jump host (ElastiCache)"
  type        = bool
  default     = false
}
