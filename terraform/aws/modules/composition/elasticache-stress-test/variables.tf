variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment short name for resource naming (e.g., sbx, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = ""
}

variable "redis_endpoint" {
  description = "Elasticache Redis/Valkey endpoint (configuration endpoint for cluster mode, primary endpoint for standalone)"
  type        = string
}

variable "redis_port" {
  description = "Redis/Valkey port"
  type        = number
  default     = 6379
}

variable "redis_cluster_mode" {
  description = "Whether Redis has cluster mode enabled. If true, uses redis.cluster.RedisCluster client connecting to configuration endpoint. If false, uses redis.Redis client connecting to primary endpoint."
  type        = bool
  default     = true
}

variable "redis_auth_token" {
  description = "AUTH token for Redis (if enabled). Leave empty for no AUTH."
  type        = string
  default     = ""
  sensitive   = true
}

variable "redis_use_tls" {
  description = "Whether Redis has TLS enabled (transit_encryption_enabled)"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where Lambda functions will be deployed"
  type        = string
}

variable "lambda_subnet_ids" {
  description = "List of subnet IDs for Lambda VPC config (use lambda subnets)"
  type        = list(string)
}

variable "create_security_group" {
  description = "Create a dedicated security group for Lambda. If false, provide lambda_security_group_id (e.g., reuse jump host SG)"
  type        = bool
  default     = false
}

variable "lambda_security_group_id" {
  description = "Existing security group ID for Lambda (required when create_security_group = false)"
  type        = string
  default     = ""
}

variable "redis_security_group_id" {
  description = "Redis security group ID (required when create_security_group = true, to add ingress rule for port 6379)"
  type        = string
  default     = ""
}

variable "lambda_runtime" {
  description = "Lambda runtime (must match compatible_runtimes of the redis-py layer)"
  type        = string
  default     = "python3.11"
}

variable "lambda_layers" {
  description = "List of Lambda layer ARNs (e.g., existing redis-py-python311 layer)"
  type        = list(string)
  default     = []
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds for stress test functions (max 900)"
  type        = number
  default     = 900
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB for stress test functions"
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 14
}

variable "stress_duration" {
  description = "Default stress test duration in seconds"
  type        = number
  default     = 300
}

variable "stress_clients" {
  description = "Default number of concurrent clients/connections for stress tests"
  type        = number
  default     = 50
}

variable "stress_threads" {
  description = "Default number of worker threads for stress tests"
  type        = number
  default     = 4
}

variable "cpu_burn_iterations" {
  description = "Number of Lua iterations in the CPU stress script (default 500k ≈ 20-50ms on cache.m6g.large)"
  type        = number
  default     = 500000
}

variable "cpu_mixed_mode" {
  description = "If true, CPU stress mixes SET/GET/INCR with Lua burn. If false, runs pure Lua burn (higher EngineCPU)."
  type        = bool
  default     = false
}

variable "memory_key_count" {
  description = "Number of keys to write for memory stress test (legacy; prefer memory_keys_per_worker)"
  type        = number
  default     = 10000
}

variable "memory_value_size_kb" {
  description = "Size of each value in KB for memory stress test"
  type        = number
  default     = 4096
}

variable "memory_workers" {
  description = "Number of per-worker threads (each with its own redis client) for memory stress test"
  type        = number
  default     = 24
}

variable "memory_keys_per_worker" {
  description = "Number of keys each memory stress worker writes before stopping"
  type        = number
  default     = 5000
}

variable "memory_pipeline_size" {
  description = "Number of SET commands per pipeline batch in memory stress test"
  type        = number
  default     = 5
}

variable "memory_write_ttl" {
  description = "TTL in seconds for memory stress keys (0 = no TTL, keys persist until eviction or cleanup)"
  type        = number
  default     = 0
}

variable "memory_cleanup_after_stress" {
  description = "If true, memory_stress automatically unlinks all stress keys before returning"
  type        = bool
  default     = true
}

variable "connection_target" {
  description = "Target number of concurrent connections for connection exhaustion test (legacy; prefer connection_target_total)"
  type        = number
  default     = 1000
}

variable "connection_threads" {
  description = "Number of worker threads for connection exhaustion test"
  type        = number
  default     = 48
}

variable "connection_batch_size" {
  description = "Number of raw TCP sockets opened per batch per worker in connection exhaustion test"
  type        = number
  default     = 100
}

variable "connection_target_total" {
  description = "Total number of held connections across all workers before switching to churn mode"
  type        = number
  default     = 850
}

variable "connection_rapid_churn" {
  description = "If true, after reaching connection_target_total workers churn (open/handshake/close) while holding the pool"
  type        = bool
  default     = false
}

variable "redis_replication_group_id" {
  description = "ElastiCache replication group ID for the failover Lambda (TestFailover API)"
  type        = string
  default     = ""
}

variable "redis_node_group_id" {
  description = "ElastiCache node group / shard ID for the failover Lambda (e.g., 0001)"
  type        = string
  default     = "0001"
}

variable "failover_timeout_seconds" {
  description = "Maximum time in seconds to wait for the replication group to return to available after TestFailover"
  type        = number
  default     = 600
}

variable "failover_poll_interval_seconds" {
  description = "Polling interval in seconds between describe_replication_groups calls during failover recovery"
  type        = number
  default     = 15
}

variable "cpu_phase_durations" {
  description = "Comma-separated phase durations in seconds for staged CPU stress (e.g. 60,300,300 = 1min warmup + 5min + 5min)"
  type        = string
  default     = "60,180,180"
}

variable "cpu_phase_threads" {
  description = "Comma-separated thread counts per CPU stress phase (e.g. 8,8,8). With the linear D/N duty model, 8 threads is usually enough for a smooth 90-97% EngineCPU plateau."
  type        = string
  default     = "8,8,8"
}

variable "cpu_phase_duty" {
  description = "Comma-separated duty cycles per CPU stress phase (e.g. 0.97,0.98,1.0). Values <1.0 throttle the aggregate offered load so EngineCPU stays below 100%."
  type        = string
  default     = "0.97,0.98,1.0"
}

variable "cpu_phase_cycle_period_seconds" {
  description = "Max random startup jitter in seconds for CPU stress workers (e.g. 2). Small jitter is enough when per-cycle jitter is also applied; large jitter distorts 1-minute CloudWatch averages."
  type        = number
  default     = 2
}

variable "memory_phase_durations" {
  description = "Comma-separated phase durations in seconds for staged memory stress (e.g. 240,240,240)"
  type        = string
  default     = "240,240,240"
}

variable "memory_phase_target_percent" {
  description = "Comma-separated target used_memory percentages of maxmemory per memory stress phase (e.g. 60,85,100)"
  type        = string
  default     = "60,85,100"
}

variable "memory_phase_workers" {
  description = "Comma-separated writer counts per memory stress phase (e.g. 8,12,24)"
  type        = string
  default     = "8,12,24"
}

variable "key_prefix" {
  description = "Prefix for all keys created by stress tests (used by cleanup function)"
  type        = string
  default     = "stress:test:"
}

variable "workload_phase_durations" {
  description = "Comma-separated phase durations in seconds for mixed workload stress (e.g. 60,180,180)"
  type        = string
  default     = "60,180,180"
}

variable "workload_phase_ops_per_sec" {
  description = "Comma-separated target total ops/sec per mixed workload phase (e.g. 20000,35000,45000)"
  type        = string
  default     = "20000,35000,45000"
}

variable "workload_command_mix" {
  description = "Command mix for mixed workload stress as command:weight pairs (e.g. get:60,set:20,hget:10,hset:5,incr:5). Weights are normalised by their total."
  type        = string
  default     = "get:60,set:20,hget:10,hset:5,incr:5"
}

variable "workload_pipeline_size" {
  description = "Number of commands per pipeline batch in mixed workload stress (1 = no pipelining)"
  type        = number
  default     = 1
}

variable "workload_key_pattern" {
  description = "Key pattern for mixed workload stress. Use {id} as placeholder for random integer in [0, workload_key_count)"
  type        = string
  default     = "stress:test:{id}"
}

variable "workload_key_count" {
  description = "Upper bound for random key ID selection in mixed workload stress (keys are in [0, workload_key_count))"
  type        = number
  default     = 100000
}

variable "workload_value_size_bytes" {
  description = "Size of random byte string values for SET/HSET commands in mixed workload stress"
  type        = number
  default     = 256
}

variable "workload_emit_cloudwatch_metrics" {
  description = "If true, mixed workload stress emits custom CloudWatch metrics (Operations, Errors, P50Latency, P99Latency) per phase"
  type        = bool
  default     = false
}

variable "workload_phase_cycle_period_seconds" {
  description = "Max random startup jitter in seconds for mixed workload workers (desynchronises thread send schedules)"
  type        = number
  default     = 2
}

variable "workload_threads" {
  description = "Number of worker threads for mixed workload stress (each with its own Redis client). Dedicated knob so the generator can scale independently of other stress types."
  type        = number
  default     = 32
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
