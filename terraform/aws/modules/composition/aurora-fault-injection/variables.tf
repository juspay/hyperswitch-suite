# ============================================================================
# Aurora Fault Injection Module - Variables
# ============================================================================

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

# ============================================================================
# Database Connection
# ============================================================================

variable "db_endpoint" {
  description = "Aurora PostgreSQL writer endpoint (cluster endpoint)"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "postgres"
}

variable "db_username" {
  description = "Master database username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Master database password (will be stored in Secrets Manager, KMS-encrypted)"
  type        = string
  sensitive   = true
}

# ============================================================================
# VPC Configuration
# ============================================================================

variable "vpc_id" {
  description = "VPC ID where Lambda functions will be deployed"
  type        = string
}

variable "lambda_subnet_ids" {
  description = "List of subnet IDs for Lambda VPC config (use lambda subnets, not DB subnets)"
  type        = list(string)
}

# ============================================================================
# Security Group
# ============================================================================

variable "create_security_group" {
  description = "Create a dedicated security group for Lambda. If false, provide lambda_security_group_id (e.g., reuse jump host SG)"
  type        = bool
  default     = false
}

variable "lambda_security_group_id" {
  description = "Existing security group ID for Lambda (required when create_security_group = false). E.g., jump host internal SG"
  type        = string
  default     = ""
}

variable "db_security_group_id" {
  description = "Database security group ID (required when create_security_group = true, to add ingress rule for port 5432)"
  type        = string
  default     = ""
}

# ============================================================================
# KMS Key
# ============================================================================

variable "kms_key_alias" {
  description = "Alias for the KMS key used to encrypt Secrets Manager secret"
  type        = string
  default     = ""
}

# ============================================================================
# Secrets Manager
# ============================================================================

variable "secret_name" {
  description = "Name of the Secrets Manager secret for DB credentials"
  type        = string
  default     = ""
}

variable "create_secret" {
  description = "Create a new Secrets Manager secret. If false, looks up an existing secret by secret_name. The existing secret must contain JSON with: username, password, host, port, dbname"
  type        = bool
  default     = true
}

# ============================================================================
# Lambda Configuration
# ============================================================================

variable "lambda_runtime" {
  description = "Lambda runtime (must match compatible_runtimes of the psycopg2 layer)"
  type        = string
  default     = "python3.11"
}

variable "lambda_layers" {
  description = "List of Lambda layer ARNs (e.g., existing psycopg2-python311 layer)"
  type        = list(string)
  default     = []
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 256
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 14
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
# Stress Test Configuration
# ============================================================================

variable "enable_stress_tests" {
  description = "Deploy stress test Lambda functions (cpu_stress, memory_stress, connection_exhaustion)"
  type        = bool
  default     = false
}

variable "stress_lambda_timeout" {
  description = "Lambda timeout in seconds for stress test functions (max 900)"
  type        = number
  default     = 900
}

variable "stress_lambda_memory_size" {
  description = "Lambda memory size in MB for stress test functions"
  type        = number
  default     = 512
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

variable "sort_connections" {
  description = "Number of concurrent sort connections for memory stress test"
  type        = number
  default     = 10
}

variable "sort_work_mem_mb" {
  description = "work_mem setting in MB for each sort connection in memory stress test"
  type        = number
  default     = 512
}

variable "sort_rows" {
  description = "Number of rows to generate and sort in each memory stress iteration"
  type        = number
  default     = 10000000
}

variable "phase_durations" {
  description = "Comma-separated phase durations in seconds (e.g. 240,300,300 = 4min+5min+5min)"
  type        = string
  default     = "240,300,300"
}

variable "cpu_phase_threads" {
  description = "Comma-separated thread count per CPU stress phase (e.g. 2,2,16)"
  type        = string
  default     = "2,2,16"
}

variable "cpu_phase_duty" {
  description = "Comma-separated duty cycles per CPU stress phase (e.g. 0.6,0.8,1.0)"
  type        = string
  default     = "0.6,0.8,1.0"
}

variable "cpu_phase_pure_cpu" {
  description = "Comma-separated booleans per CPU stress phase. When true, the phase uses a read-only generate_series CPU-burn query instead of TPC-B writes (e.g. false,false,true)"
  type        = string
  default     = "false,false,true"
}

variable "cpu_phase_targets" {
  description = "Comma-separated target CPU percentages per phase. When set, active connection count is used instead of threads/duty (e.g. 70,75,80). Formula: effective_connections = target_pct/100 * cpu_vcpus."
  type        = string
  default     = ""
}

variable "cpu_vcpus" {
  description = "Number of vCPUs on the Aurora instance. Used to compute active connection count when cpu_phase_targets is set."
  type        = number
  default     = 4
}

variable "cpu_phase_baseline_pct" {
  description = "Estimated CPU percentage consumed by the TPC-B workload alone. When cpu_phase_targets is set, the boost is computed as target - baseline."
  type        = number
  default     = 87.0
}

variable "cpu_phase_extra_threads" {
  description = "Comma-separated extra pure-CPU worker threads per phase, added on top of TPC-B and target-boost workers (e.g. 0,1,3)."
  type        = string
  default     = "0,0,0"
}

variable "cpu_pure_cpu_series_count" {
  description = "Number of rows for the pure-CPU generate_series query in pure_cpu phases. Smaller rows with more queries per loop keeps the DB pipeline full."
  type        = number
  default     = 1000000
}

variable "cpu_pure_cpu_queries_per_loop" {
  description = "Number of pure-CPU queries to issue back-to-back before duty-cycle sleep. Higher values keep the CPU pipeline fuller."
  type        = number
  default     = 10
}

variable "mem_phase_idle" {
  description = "Comma-separated cumulative idle connection counts per memory stress phase (e.g. 50,150,300)"
  type        = string
  default     = "50,150,300"
}

variable "mem_phase_sort" {
  description = "Comma-separated cumulative sort session counts per memory stress phase (e.g. 5,10,20)"
  type        = string
  default     = "5,10,20"
}

variable "mem_phase_temp_mb" {
  description = "Comma-separated temp_buffers MB per memory stress phase (e.g. 256,512,1024)"
  type        = string
  default     = "256,512,1024"
}

variable "mem_phase_agg_rows" {
  description = "Comma-separated array_agg row counts per memory stress phase (e.g. 5000000,10000000,20000000)"
  type        = string
  default     = "5000000,10000000,20000000"
}

variable "mem_phase_durations" {
  description = "Comma-separated memory stress phase durations in seconds. Defaults to PHASE_DURATIONS if unset."
  type        = string
  default     = ""
}

variable "mem_work_mem_mb" {
  description = "work_mem in MB for each memory stress worker session. Higher values force more in-memory operations and pressure shared resources."
  type        = number
  default     = 512
}

variable "mem_agg_rows_max" {
  description = "Maximum array_agg rows per worker. Raise to build larger in-memory arrays."
  type        = number
  default     = 20000000
}

variable "mem_arrays_per_worker" {
  description = "Number of large arrays each worker holds simultaneously. Higher values consume memory faster."
  type        = number
  default     = 3
}

variable "mem_temp_rows_max" {
  description = "Maximum rows per temp table worker. Larger temp tables consume more temp_buffers memory."
  type        = number
  default     = 5000000
}

variable "conn_phase_threads" {
  description = "Comma-separated cumulative thread counts per connection exhaustion phase (e.g. 20,40,56)"
  type        = string
  default     = "20,40,56"
}

variable "conn_batch_size" {
  description = "Connections per thread per batch in connection exhaustion test"
  type        = number
  default     = 30
}

variable "conn_hold_seconds" {
  description = "Seconds to hold connections before closing in connection exhaustion test"
  type        = number
  default     = 5
}

variable "conn_ramp_seconds" {
  description = "Seconds over which each worker spreads its connection openings to avoid a steep spike"
  type        = number
  default     = 60
}
