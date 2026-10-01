# ============================================================================
# Aurora Fault Injection & Stress Test Module - Main Resources
# ============================================================================
# Creates:
#   1. KMS key for Secrets Manager encryption + Lambda password decrypt
#   2. Secrets Manager secret storing DB credentials (user-provided or existing)
#   3. IAM role for Lambda (VPC access, Secrets Manager, KMS, CloudWatch)
#   4. Optional security group (or reuse existing, e.g., jump host SG)
#   5. Six Lambda functions for Aurora fault injection queries (src/aurora_inject/)
#   6. Three Lambda functions for Aurora stress testing (src/stress_test/)
#   Uses existing psycopg2 Lambda layer (provided via var.lambda_layers)
# ============================================================================

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform-IaC"
    Component   = "aurora-fault-injection"
  })

  kms_alias   = var.kms_key_alias != "" ? var.kms_key_alias : "alias/${var.environment}-aurora-fi-kms"
  secret_name = var.secret_name != "" ? var.secret_name : "rds/${var.environment}-test-rds-master-credentials"

  fault_types = {
    crash_instance   = { handler = "crash_instance.lambda_handler", description = "Inject DB process crash (instance)" }
    crash_dispatcher = { handler = "crash_dispatcher.lambda_handler", description = "Inject dispatcher crash (writes to cluster volume)" }
    crash_node       = { handler = "crash_node.lambda_handler", description = "Inject both DB + dispatcher crash (node)" }
    replica_failure  = { handler = "replica_failure.lambda_handler", description = "Inject replica failure (100% block, 30s)" }
    disk_failure     = { handler = "disk_failure.lambda_handler", description = "Inject disk failure (50% storage, 20s)" }
    disk_congestion  = { handler = "disk_congestion.lambda_handler", description = "Inject disk congestion (100% I/O, 60s, 30-100ms)" }
  }

  stress_types = var.enable_stress_tests ? {
    cpu_stress            = { handler = "cpu_stress.lambda_handler", description = "CPU stress via TPC-B-like concurrent workload (ThreadPoolExecutor + psycopg2)" }
    memory_stress         = { handler = "memory_stress.lambda_handler", description = "Memory stress via connection flooding + large sorts" }
    connection_exhaustion = { handler = "connection_exhaustion.lambda_handler", description = "Connection pool exhaustion via rapid connect/disconnect" }
    cleanup               = { handler = "cleanup.lambda_handler", description = "Drop pgbench tables created by cpu_stress (run after testing)" }
  } : {}

  effective_security_group_id = var.create_security_group ? aws_security_group.lambda[0].id : var.lambda_security_group_id
}

# ============================================================================
# KMS Key for Secrets Manager Encryption + Lambda Password Decrypt
# ============================================================================

resource "aws_kms_key" "this" {
  description             = "KMS key for Aurora fault injection Secrets Manager encryption (${var.environment})"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableIAMUserPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowLambdaDecrypt"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.lambda.arn }
        Action    = ["kms:Decrypt", "kms:DescribeKey"]
        Resource  = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_kms_alias" "this" {
  name          = local.kms_alias
  target_key_id = aws_kms_key.this.key_id
}

data "aws_caller_identity" "current" {}

# ============================================================================
# Secrets Manager - DB Credentials
# When create_secret = true: creates a new secret with KMS encryption
# When create_secret = false: looks up an existing secret by name (user-created)
# ============================================================================

resource "aws_secretsmanager_secret" "db_credentials" {
  count = var.create_secret ? 1 : 0

  name                    = local.secret_name
  description             = "Aurora PostgreSQL credentials for fault injection Lambda (${var.environment})"
  kms_key_id              = aws_kms_key.this.key_id
  recovery_window_in_days = 0

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  count = var.create_secret ? 1 : 0

  secret_id = aws_secretsmanager_secret.db_credentials[0].id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_endpoint
    port     = var.db_port
    dbname   = var.db_name
  })
}

data "aws_secretsmanager_secret" "existing" {
  count = var.create_secret ? 0 : 1
  name  = local.secret_name
}

locals {
  secret_arn = var.create_secret ? aws_secretsmanager_secret.db_credentials[0].arn : data.aws_secretsmanager_secret.existing[0].arn
}

# ============================================================================
# IAM Role for Lambda Functions
# ============================================================================

resource "aws_iam_role" "lambda" {
  name = "${var.environment}-aurora-fi-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy" "secrets_and_kms" {
  name = "secrets-kms-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetSecretValue"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          local.secret_arn
        ]
      },
      {
        Sid    = "KMSDecryptSecret"
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:DescribeKey"]
        Resource = [
          aws_kms_key.this.arn
        ]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.region}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "KMSDecryptPassword"
        Effect = "Allow"
        Action = ["kms:Decrypt"]
        Resource = [
          aws_kms_key.this.arn
        ]
      }
    ]
  })
}

# ============================================================================
# Optional Security Group (create or reuse existing)
# ============================================================================

resource "aws_security_group" "lambda" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.environment}-aurora-fi-lambda-sg"
  description = "Security group for Aurora fault injection Lambda functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group_rule" "db_ingress_lambda" {
  count = var.create_security_group ? 1 : 0

  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = var.db_security_group_id
  source_security_group_id = aws_security_group.lambda[0].id
}

# ============================================================================
# Lambda Source Code Zips
# ============================================================================

data "archive_file" "fault_injection_code" {
  type        = "zip"
  source_dir  = "${path.module}/src/aurora_inject"
  output_path = "${path.module}/build/fault-injection-code.zip"
}

data "archive_file" "stress_test_code" {
  type        = "zip"
  source_dir  = "${path.module}/src/stress_test"
  output_path = "${path.module}/build/stress-test-code.zip"
}

# ============================================================================
# CloudWatch Log Groups
# ============================================================================

resource "aws_cloudwatch_log_group" "fault_injection" {
  for_each          = local.fault_types
  name              = "/aws/lambda/${var.environment}-aurora-fi-${each.key}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "stress_test" {
  for_each          = local.stress_types
  name              = "/aws/lambda/${var.environment}-aurora-stress-${each.key}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

# ============================================================================
# Lambda Functions - Fault Injection (6 functions, src/aurora_inject/)
# ============================================================================

resource "aws_lambda_function" "fault_injection" {
  for_each = local.fault_types

  function_name = "${var.environment}-aurora-fi-${each.key}"
  description   = each.value.description

  role    = aws_iam_role.lambda.arn
  runtime = var.lambda_runtime
  handler = each.value.handler

  filename         = data.archive_file.fault_injection_code.output_path
  source_code_hash = data.archive_file.fault_injection_code.output_base64sha256

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  layers = var.lambda_layers

  environment {
    variables = {
      SECRET_ARN  = local.secret_arn
      KMS_KEY_ARN = aws_kms_key.this.arn
      DB_HOST     = var.db_endpoint
      DB_PORT     = tostring(var.db_port)
      DB_NAME     = var.db_name
      DB_USER     = var.db_username
      FAULT_TYPE  = each.key
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [local.effective_security_group_id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy.secrets_and_kms,
    aws_cloudwatch_log_group.fault_injection,
    aws_secretsmanager_secret_version.db_credentials,
  ]

  tags = merge(local.common_tags, {
    FaultType = each.key
  })
}

# ============================================================================
# Lambda Functions - Stress Test (3 functions, src/stress_test/)
# ============================================================================

resource "aws_lambda_function" "stress_test" {
  for_each = local.stress_types

  function_name = "${var.environment}-aurora-stress-${each.key}"
  description   = each.value.description

  role    = aws_iam_role.lambda.arn
  runtime = var.lambda_runtime
  handler = each.value.handler

  filename         = data.archive_file.stress_test_code.output_path
  source_code_hash = data.archive_file.stress_test_code.output_base64sha256

  timeout     = var.stress_lambda_timeout
  memory_size = var.stress_lambda_memory_size

  layers = var.lambda_layers

  environment {
    variables = {
      SECRET_ARN                    = local.secret_arn
      KMS_KEY_ARN                   = aws_kms_key.this.arn
      DB_HOST                       = var.db_endpoint
      DB_PORT                       = tostring(var.db_port)
      DB_NAME                       = var.db_name
      DB_USER                       = var.db_username
      STRESS_TYPE                   = each.key
      DURATION                      = tostring(var.stress_duration)
      CLIENTS                       = tostring(var.stress_clients)
      THREADS                       = tostring(var.stress_threads)
      SORT_CONNECTIONS              = tostring(var.sort_connections)
      SORT_WORK_MEM_MB              = tostring(var.sort_work_mem_mb)
      SORT_ROWS                     = tostring(var.sort_rows)
      PHASE_DURATIONS               = var.phase_durations
      CPU_PHASE_THREADS             = var.cpu_phase_threads
      CPU_PHASE_DUTY                = var.cpu_phase_duty
      CPU_PHASE_PURE_CPU            = var.cpu_phase_pure_cpu
      CPU_PHASE_TARGETS             = var.cpu_phase_targets
      CPU_VCPUS                     = tostring(var.cpu_vcpus)
      CPU_PHASE_BASELINE_PCT        = tostring(var.cpu_phase_baseline_pct)
      CPU_PHASE_EXTRA_THREADS       = var.cpu_phase_extra_threads
      CPU_PURE_CPU_SERIES_COUNT     = tostring(var.cpu_pure_cpu_series_count)
      CPU_PURE_CPU_QUERIES_PER_LOOP = tostring(var.cpu_pure_cpu_queries_per_loop)
      MEM_PHASE_IDLE                = var.mem_phase_idle
      MEM_PHASE_SORT                = var.mem_phase_sort
      MEM_PHASE_TEMP_MB             = var.mem_phase_temp_mb
      MEM_PHASE_AGG_ROWS            = var.mem_phase_agg_rows
      MEM_PHASE_DURATIONS           = var.mem_phase_durations
      MEM_WORK_MEM_MB               = tostring(var.mem_work_mem_mb)
      MEM_AGG_ROWS_MAX              = tostring(var.mem_agg_rows_max)
      MEM_ARRAYS_PER_WORKER         = tostring(var.mem_arrays_per_worker)
      MEM_TEMP_ROWS_MAX             = tostring(var.mem_temp_rows_max)
      CONN_PHASE_THREADS            = var.conn_phase_threads
      CONN_BATCH_SIZE               = tostring(var.conn_batch_size)
      CONN_HOLD_SECONDS             = tostring(var.conn_hold_seconds)
      CONN_RAMP_SECONDS             = tostring(var.conn_ramp_seconds)
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [local.effective_security_group_id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy.secrets_and_kms,
    aws_cloudwatch_log_group.stress_test,
    aws_secretsmanager_secret_version.db_credentials,
  ]

  tags = merge(local.common_tags, {
    StressType = each.key
  })
}
