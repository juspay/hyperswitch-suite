locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform-IaC"
    Component   = "elasticache-stress-test"
  })

  lambda_common_environment = {
    REDIS_HOST                          = var.redis_endpoint
    REDIS_PORT                          = tostring(var.redis_port)
    CLUSTER_MODE                        = tostring(var.redis_cluster_mode)
    REDIS_AUTH_TOKEN                    = var.redis_auth_token
    REDIS_USE_TLS                       = tostring(var.redis_use_tls)
    DURATION                            = tostring(var.stress_duration)
    STRESS_DURATION                     = tostring(var.stress_duration)
    CLIENTS                             = tostring(var.stress_clients)
    THREADS                             = tostring(var.stress_threads)
    STRESS_THREADS                      = tostring(var.stress_threads)
    CPU_BURN_ITERATIONS                 = tostring(var.cpu_burn_iterations)
    CPU_MIXED_MODE                      = tostring(var.cpu_mixed_mode)
    CPU_PHASE_DURATIONS                 = var.cpu_phase_durations
    CPU_PHASE_THREADS                   = var.cpu_phase_threads
    CPU_PHASE_DUTY                      = var.cpu_phase_duty
    CPU_PHASE_CYCLE_PERIOD_SECONDS      = tostring(var.cpu_phase_cycle_period_seconds)
    MEMORY_KEY_COUNT                    = tostring(var.memory_key_count)
    MEMORY_VALUE_SIZE                   = tostring(var.memory_value_size_kb)
    MEMORY_WORKERS                      = tostring(var.memory_workers)
    MEMORY_KEYS_PER_WORKER              = tostring(var.memory_keys_per_worker)
    MEMORY_PIPELINE_SIZE                = tostring(var.memory_pipeline_size)
    MEMORY_WRITE_TTL                    = tostring(var.memory_write_ttl)
    MEMORY_CLEANUP_AFTER_STRESS         = tostring(var.memory_cleanup_after_stress)
    MEMORY_PHASE_DURATIONS              = var.memory_phase_durations
    MEMORY_PHASE_TARGET_PERCENT         = var.memory_phase_target_percent
    MEMORY_PHASE_WORKERS                = var.memory_phase_workers
    CONNECTION_TARGET                   = tostring(var.connection_target)
    CONNECTION_THREADS                  = tostring(var.connection_threads)
    CONNECTION_BATCH_SIZE               = tostring(var.connection_batch_size)
    CONNECTION_TARGET_TOTAL             = tostring(var.connection_target_total)
    CONNECTION_RAPID_CHURN              = tostring(var.connection_rapid_churn)
    KEY_PREFIX                          = var.key_prefix
    ENVIRONMENT                         = var.environment
    WORKLOAD_PHASE_DURATIONS            = var.workload_phase_durations
    WORKLOAD_PHASE_OPS_PER_SEC          = var.workload_phase_ops_per_sec
    WORKLOAD_COMMAND_MIX                = var.workload_command_mix
    WORKLOAD_PIPELINE_SIZE              = tostring(var.workload_pipeline_size)
    WORKLOAD_KEY_PATTERN                = var.workload_key_pattern
    WORKLOAD_KEY_COUNT                  = tostring(var.workload_key_count)
    WORKLOAD_VALUE_SIZE_BYTES           = tostring(var.workload_value_size_bytes)
    WORKLOAD_EMIT_CLOUDWATCH_METRICS    = tostring(var.workload_emit_cloudwatch_metrics)
    WORKLOAD_PHASE_CYCLE_PERIOD_SECONDS = tostring(var.workload_phase_cycle_period_seconds)
    WORKLOAD_THREADS                    = tostring(var.workload_threads)
  }

  stress_types = {
    cpu_stress            = { handler = "cpu_stress.lambda_handler", description = "CPU stress via concurrent SET/GET/INCR + Lua script CPU burn (ThreadPoolExecutor + redis-py)" }
    mixed_workload        = { handler = "mixed_workload.lambda_handler", description = "Open-loop mixed Redis/Valkey command workload (GET/SET/HGET/HSET/INCR) with fixed arrival rate and latency percentile measurement" }
    memory_stress         = { handler = "memory_stress.lambda_handler", description = "Memory stress via large value writes to fill maxmemory and trigger evictions" }
    connection_exhaustion = { handler = "connection_exhaustion.lambda_handler", description = "Connection pool exhaustion via rapid connect/disconnect flooding" }
    cleanup               = { handler = "cleanup.lambda_handler", description = "Delete all keys with stress test prefix (run after testing)" }
    connection_orchestrator = {
      handler     = "connection_orchestrator.lambda_handler"
      description = "Orchestrate multiple connection_exhaustion Lambdas and centrally manage Redis maxclients"
      timeout     = 900
      memory_size = 512
      environment = {
        WORKER_FUNCTION_NAME             = "${var.environment}-elasticache-stress-connection_exhaustion"
        WORKER_REGION                    = var.region
        ORCHESTRATOR_WORKER_COUNT        = "84"
        ORCHESTRATOR_DESIRED_TOTAL       = "70000"
        ORCHESTRATOR_MAX_PER_WORKER      = "850"
        ORCHESTRATOR_DURATION            = "600"
        ORCHESTRATOR_WORKER_TARGET_TOTAL = "850"
        ORCHESTRATOR_WORKER_THREADS      = "16"
        ORCHESTRATOR_WORKER_BATCH_SIZE   = "10"
        TARGET_PRIMARY_ONLY              = "false"
      }
    }
    failover = {
      handler                = "failover.lambda_handler"
      description            = "Trigger Elasticache TestFailover on the Valkey replication group and poll until available"
      timeout                = 900
      memory_size            = 256
      layers                 = []
      include_vpc_config     = false
      use_common_environment = false
      environment = {
        REDIS_REPLICATION_GROUP_ID = var.redis_replication_group_id
        REDIS_NODE_GROUP_ID        = var.redis_node_group_id
      }
    }
  }

  effective_security_group_id = var.create_security_group ? aws_security_group.lambda[0].id : var.lambda_security_group_id

  redis_replication_group_arn = "arn:aws:elasticache:${var.region}:${data.aws_caller_identity.current.account_id}:replicationgroup:${var.redis_replication_group_id}"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda" {
  name = "${var.environment}-elasticache-stress-lambda-role"

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

resource "aws_iam_role_policy" "elasticache_failover" {
  name = "${var.environment}-elasticache-failover"
  role = aws_iam_role.lambda.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["elasticache:TestFailover", "elasticache:DescribeReplicationGroups"]
      Resource = local.redis_replication_group_arn
    }]
  })
}

resource "aws_iam_role_policy" "lambda_invoke_worker" {
  name = "${var.environment}-elasticache-invoke-worker"
  role = aws_iam_role.lambda.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.environment}-elasticache-stress-connection_exhaustion"
    }]
  })
}

resource "aws_iam_role_policy" "cloudwatch_metrics" {
  name = "${var.environment}-elasticache-cloudwatch-metrics"
  role = aws_iam_role.lambda.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "cloudwatch:PutMetricData"
      Resource = "*"
    }]
  })
}

resource "aws_security_group" "lambda" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.environment}-elasticache-stress-lambda-sg"
  description = "Security group for Elasticache stress test Lambda functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group_rule" "redis_ingress_lambda" {
  count = var.create_security_group ? 1 : 0

  type                     = "ingress"
  from_port                = var.redis_port
  to_port                  = var.redis_port
  protocol                 = "tcp"
  security_group_id        = var.redis_security_group_id
  source_security_group_id = aws_security_group.lambda[0].id
}

data "archive_file" "stress_test_code" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/stress-test-code.zip"
}

resource "aws_cloudwatch_log_group" "stress_test" {
  for_each          = local.stress_types
  name              = "/aws/lambda/${var.environment}-elasticache-stress-${each.key}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_lambda_function" "stress_test" {
  for_each = local.stress_types

  function_name = "${var.environment}-elasticache-stress-${each.key}"
  description   = each.value.description

  role    = aws_iam_role.lambda.arn
  runtime = var.lambda_runtime
  handler = each.value.handler

  filename         = data.archive_file.stress_test_code.output_path
  source_code_hash = data.archive_file.stress_test_code.output_base64sha256

  timeout     = lookup(each.value, "timeout", var.lambda_timeout)
  memory_size = lookup(each.value, "memory_size", var.lambda_memory_size)

  layers = lookup(each.value, "layers", var.lambda_layers)

  environment {
    variables = merge(
      lookup(each.value, "use_common_environment", true) ? local.lambda_common_environment : {},
      { STRESS_TYPE = each.key },
      lookup(each.value, "environment", {})
    )
  }

  dynamic "vpc_config" {
    for_each = lookup(each.value, "include_vpc_config", true) ? [1] : []
    content {
      subnet_ids         = var.lambda_subnet_ids
      security_group_ids = [local.effective_security_group_id]
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy.elasticache_failover,
    aws_iam_role_policy.cloudwatch_metrics,
    aws_cloudwatch_log_group.stress_test,
  ]

  tags = merge(local.common_tags, {
    StressType = each.key
  })
}
