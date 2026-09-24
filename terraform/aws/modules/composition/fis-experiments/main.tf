# ============================================================================
# FIS Experiments Module - Main Resources
# ============================================================================
# Creates:
#   1. IAM role + inline policy for FIS experiment execution
#   2. CloudWatch metric alarm as stop condition (CPU > 95% for 2 min)
#   3. CloudWatch metric alarm: FreeableMemory < 2GB (stop condition)
#   4. CloudWatch metric alarm: DatabaseConnections > 68 (stop condition)
#   5. FIS experiment template: Aurora cluster failover
#   6. FIS experiment template: DB instance reboot
#   7. FIS experiment template: Combined failover + wait + reboot
#   8. FIS experiment template: Network connectivity loss to DB
#   9. FIS experiment template: AZ power interruption (compound)
#  10. FIS experiment template: CPU stress via Lambda (SSM → aws lambda invoke)
#  11. FIS experiment template: Memory stress via Lambda (SSM → aws lambda invoke)
#  12. FIS experiment template: Connection exhaustion via Lambda
#  13. CloudWatch metric alarm: Redis ReplicationLag (stop condition)
#  14. FIS experiment template: Redis replication group failover (standalone)
#  15. FIS experiment template: Redis failover under CPU stress
#  16. FIS experiment template: Network latency injection on EC2 (tc netem via SSM)
#  17. FIS experiment template: Simple network latency on EC2 (all traffic, tc netem)
#  18. FIS experiment template: EC2 instance termination
# ============================================================================

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform-IaC"
    Component   = "fis-experiments"
  })

  network_latency_target_environment_tag = var.network_latency_target_environment_tag != "" ? var.network_latency_target_environment_tag : var.environment
  network_latency_use_service_names      = length(var.network_latency_target_service_names) > 0
  network_latency_template_keys          = local.network_latency_use_service_names ? toset(var.network_latency_target_service_names) : toset(["default"])
  network_latency_service_tags = local.network_latency_use_service_names ? {
    for svc in var.network_latency_target_service_names :
    svc => {
      Environment = local.network_latency_target_environment_tag
      Service     = svc
    }
  } : {}
}

# ============================================================================
# IAM Role for FIS Experiment Execution
# ============================================================================

resource "aws_iam_role" "fis_execution" {
  name        = "${var.fis_role_name}-${var.environment}"
  description = "IAM role for AWS Fault Injection Service experiment execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "fis.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "fis_execution" {
  name = "fis-experiment-permissions"
  role = aws_iam_role.fis_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:FailoverDBCluster"
        ]
        Resource = "arn:aws:rds:*:*:cluster:*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:RebootDBInstance"
        ]
        Resource = "arn:aws:rds:*:*:db:*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "tag:GetResources",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn != "" ? var.kms_key_arn : "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:CreateNetworkAcl",
          "ec2:CreateNetworkAclEntry",
          "ec2:ReplaceNetworkAclAssociation",
          "ec2:DeleteNetworkAcl",
          "ec2:DeleteNetworkAclEntry",
          "ec2:TerminateInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:CancelCommands",
          "ssm:GetCommandInvocation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = concat(
          var.stress_lambda_arns,
          var.redis_stress_lambda_arns,
          var.redis_failover_lambda_function_arn != "" ? [var.redis_failover_lambda_function_arn] : []
        )
      }
    ]
  })
}

# ============================================================================
# CloudWatch Alarm - Stop Condition
# ============================================================================
# Triggers if RDS CPU stays above 95% for 2 minutes, stopping the experiment

resource "aws_cloudwatch_metric_alarm" "fis_stop_condition" {
  alarm_name          = "fis-stop-${var.rds_cluster_identifier}"
  alarm_description   = "Stop condition for FIS experiments - triggers if CPU > 95% for 2 minutes"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 95
  period              = 60
  evaluation_periods  = 2
  statistic           = "Average"

  dimensions = {
    DBClusterIdentifier = var.rds_cluster_identifier
  }

  tags = local.common_tags
}

# ============================================================================
# CloudWatch Alarm - Stop Condition: Low FreeableMemory
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "fis_stop_memory" {
  count               = var.enable_stress_alarms ? 1 : 0
  alarm_name          = "fis-stop-memory-${var.rds_cluster_identifier}"
  alarm_description   = "Stop condition for FIS experiments - triggers if FreeableMemory drops below 2GB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeableMemory"
  comparison_operator = "LessThanThreshold"
  threshold           = 2048000000
  period              = 60
  evaluation_periods  = 2
  statistic           = "Minimum"

  dimensions = {
    DBClusterIdentifier = var.rds_cluster_identifier
  }

  tags = local.common_tags
}

# ============================================================================
# CloudWatch Alarm - Stop Condition: High Connection Count
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "fis_stop_connections" {
  count               = var.enable_stress_alarms ? 1 : 0
  alarm_name          = "fis-stop-connections-${var.rds_cluster_identifier}"
  alarm_description   = "Stop condition for FIS experiments - triggers if connections exceed 80% of max"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 68
  period              = 60
  evaluation_periods  = 2
  statistic           = "Maximum"

  dimensions = {
    DBClusterIdentifier = var.rds_cluster_identifier
  }

  tags = local.common_tags
}

# ============================================================================
# FIS Experiment Template 1: Aurora Cluster Failover
# ============================================================================

resource "aws_fis_experiment_template" "aurora_failover" {
  count       = var.enable_failover ? 1 : 0
  description = "Trigger Aurora PostgreSQL cluster failover in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  action {
    name        = "aurora-failover"
    action_id   = "aws:rds:failover-db-cluster"
    description = "Failover Aurora PostgreSQL cluster to a replica"

    target {
      key   = "Clusters"
      value = "aurora-cluster-target"
    }
  }

  target {
    name           = "aurora-cluster-target"
    resource_type  = "aws:rds:cluster"
    selection_mode = "COUNT(1)"
    resource_arns  = [var.rds_cluster_arn]
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "aurora-failover"
  })
}

# ============================================================================
# FIS Experiment Template 2: DB Instance Reboot
# ============================================================================

resource "aws_fis_experiment_template" "rds_reboot" {
  count       = var.enable_reboot ? 1 : 0
  description = "Reboot RDS DB instances in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  action {
    name        = "rds-reboot"
    action_id   = "aws:rds:reboot-db-instances"
    description = "Reboot RDS DB instances"

    target {
      key   = "DBInstances"
      value = "rds-instance-target"
    }
  }

  target {
    name           = "rds-instance-target"
    resource_type  = "aws:rds:db"
    selection_mode = "ALL"
    resource_arns  = var.rds_instance_arns
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "rds-reboot"
  })
}

# ============================================================================
# FIS Experiment Template 3: Combined Failover + Wait + Reboot
# ============================================================================

resource "aws_fis_experiment_template" "combined_failover_reboot" {
  count       = var.enable_combined ? 1 : 0
  description = "Failover Aurora cluster, wait, then reboot instances in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  action {
    name      = "step1-failover"
    action_id = "aws:rds:failover-db-cluster"

    target {
      key   = "Clusters"
      value = "aurora-cluster-target-combined"
    }
  }

  action {
    name        = "step2-wait"
    action_id   = "aws:fis:wait"
    start_after = ["step1-failover"]

    parameter {
      key   = "duration"
      value = "PT5M"
    }
  }

  action {
    name        = "step3-reboot"
    action_id   = "aws:rds:reboot-db-instances"
    start_after = ["step2-wait"]

    target {
      key   = "DBInstances"
      value = "rds-instance-target-combined"
    }
  }

  target {
    name           = "aurora-cluster-target-combined"
    resource_type  = "aws:rds:cluster"
    selection_mode = "COUNT(1)"
    resource_arns  = [var.rds_cluster_arn]
  }

  target {
    name           = "rds-instance-target-combined"
    resource_type  = "aws:rds:db"
    selection_mode = "ALL"
    resource_arns  = var.rds_instance_arns
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "combined-failover-reboot"
  })
}

# ============================================================================
# FIS Experiment Template 4: Network Connectivity Loss to DB Instance
# ============================================================================
# Uses awscc provider because the aws provider doesn't support
# "NetworkInterfaces" as a target key for aws:network:disrupt-connectivity.

resource "awscc_fis_experiment_template" "network_disruption" {
  count       = var.enable_network_disruption ? 1 : 0
  description = "Disrupt network connectivity to test DB instance for ${var.network_disruption_duration} in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_conditions = [
    {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
    }
  ]

  actions = {
    "network-disrupt" = {
      action_id   = "aws:network:disrupt-connectivity"
      description = "Deny all traffic to/from the test DB instance network interfaces"
      parameters = {
        duration = var.network_disruption_duration
      }
      targets = {
        NetworkInterfaces = "db-instance-enis"
      }
    }
  }

  targets = {
    "db-instance-enis" = {
      resource_type  = "aws:ec2:network-interfaces"
      selection_mode = "ALL"
      filters = [
        {
          path   = "group-id"
          values = [var.rds_security_group_id]
        }
      ]
    }
  }

  experiment_options = {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "network-disruption"
  })
}

# ============================================================================
# FIS Experiment Template 5: DB AZ Power Interruption (Compound)
# ============================================================================
# Simulates the DB instance losing power in its AZ:
#   1. Disrupt network to the DB's ENIs in the target AZ (duration = 30 min)
#   2. Reboot the DB instance (simulates power loss crash)
# RDS instances are not EC2 — no EBS volumes to pause, no ec2:StopInstances.

resource "awscc_fis_experiment_template" "az_power_interruption" {
  count       = var.enable_az_interruption ? 1 : 0
  description = "DB AZ power interruption: network disruption + DB reboot in ${var.target_az} for ${var.az_interruption_duration} in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_conditions = [
    {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
    }
  ]

  actions = {
    "disrupt-db-network" = {
      action_id   = "aws:network:disrupt-connectivity"
      description = "Deny all traffic to/from the DB instance ENIs in target AZ"
      parameters = {
        duration = var.az_interruption_duration
      }
      targets = {
        NetworkInterfaces = "db-az-enis"
      }
    }

    "reboot-db" = {
      action_id   = "aws:rds:reboot-db-instances"
      description = "Reboot DB instance to simulate power loss crash"
      start_after = ["disrupt-db-network"]
      targets = {
        DBInstances = "db-az-instance"
      }
    }
  }

  targets = {
    "db-az-enis" = {
      resource_type  = "aws:ec2:network-interfaces"
      selection_mode = "ALL"
      filters = [
        {
          path   = "group-id"
          values = [var.rds_security_group_id]
        },
        {
          path   = "availabilityZone"
          values = [var.target_az]
        }
      ]
    }

    "db-az-instance" = {
      resource_type  = "aws:rds:db"
      selection_mode = "ALL"
      resource_arns  = var.rds_instance_arns
    }
  }

  experiment_options = {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "az-power-interruption"
  })
}

# ============================================================================
# FIS Experiment Template 6: CPU Stress via Lambda (SSM → aws lambda invoke)
# ============================================================================
# FIS sends SSM command to jump host, which invokes the CPU stress Lambda.
# The Lambda runs a TPC-B-like concurrent workload via ThreadPoolExecutor.
# Requires: jump host instance profile must have lambda:InvokeFunction permission.

resource "aws_fis_experiment_template" "cpu_stress_lambda" {
  count       = var.enable_stress_tests && var.jumphost_instance_id != "" && length(var.stress_lambda_arns) > 0 ? 1 : 0
  description = "Trigger CPU stress test Lambda via SSM on jump host in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  dynamic "stop_condition" {
    for_each = var.enable_stress_alarms ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.fis_stop_memory[0].arn
    }
  }

  action {
    name        = "cpu-stress-via-lambda"
    action_id   = "aws:ssm:send-command"
    description = "Invoke CPU stress Lambda function via SSM on jump host"

    parameter {
      key   = "duration"
      value = "PT${var.stress_duration_seconds / 60}M"
    }

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        commands = [
          "aws lambda invoke --function-name ${var.stress_lambda_function_names["cpu_stress"]} --region ${var.region} --payload '{}' /tmp/cpu-stress-output.json && cat /tmp/cpu-stress-output.json"
        ]
      })
    }

    target {
      key   = "Instances"
      value = "jumphost-target-cpu"
    }
  }

  target {
    name           = "jumphost-target-cpu"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"
    resource_arns  = ["arn:aws:ec2:${var.region}:${var.account_id}:instance/${var.jumphost_instance_id}"]
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "cpu-stress-lambda"
  })
}

# ============================================================================
# FIS Experiment Template 7: Memory Stress via Lambda
# ============================================================================

resource "aws_fis_experiment_template" "memory_stress_lambda" {
  count       = var.enable_stress_tests && var.jumphost_instance_id != "" && length(var.stress_lambda_arns) > 0 ? 1 : 0
  description = "Trigger memory stress test Lambda via SSM on jump host in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  dynamic "stop_condition" {
    for_each = var.enable_stress_alarms ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.fis_stop_memory[0].arn
    }
  }

  dynamic "stop_condition" {
    for_each = var.enable_stress_alarms ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.fis_stop_connections[0].arn
    }
  }

  action {
    name        = "memory-stress-via-lambda"
    action_id   = "aws:ssm:send-command"
    description = "Invoke memory stress Lambda function via SSM on jump host"

    parameter {
      key   = "duration"
      value = "PT${var.stress_duration_seconds / 60}M"
    }

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        commands = [
          "aws lambda invoke --function-name ${var.stress_lambda_function_names["memory_stress"]} --region ${var.region} --payload '{}' /tmp/memory-stress-output.json && cat /tmp/memory-stress-output.json"
        ]
      })
    }

    target {
      key   = "Instances"
      value = "jumphost-target-memory"
    }
  }

  target {
    name           = "jumphost-target-memory"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"
    resource_arns  = ["arn:aws:ec2:${var.region}:${var.account_id}:instance/${var.jumphost_instance_id}"]
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "memory-stress-lambda"
  })
}

# ============================================================================
# FIS Experiment Template 8: Connection Pool Exhaustion via Lambda
# ============================================================================

resource "aws_fis_experiment_template" "connection_exhaustion_lambda" {
  count       = var.enable_stress_tests && var.jumphost_instance_id != "" && length(var.stress_lambda_arns) > 0 ? 1 : 0
  description = "Trigger connection exhaustion test Lambda via SSM on jump host in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  dynamic "stop_condition" {
    for_each = var.enable_stress_alarms ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.fis_stop_connections[0].arn
    }
  }

  action {
    name        = "conn-exhaustion-via-lambda"
    action_id   = "aws:ssm:send-command"
    description = "Invoke connection exhaustion Lambda function via SSM on jump host"

    parameter {
      key   = "duration"
      value = "PT${var.stress_duration_seconds / 60}M"
    }

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        commands = [
          "aws lambda invoke --function-name ${var.stress_lambda_function_names["connection_exhaustion"]} --region ${var.region} --payload '{}' /tmp/conn-exhaust-output.json && cat /tmp/conn-exhaust-output.json"
        ]
      })
    }

    target {
      key   = "Instances"
      value = "jumphost-target-conn"
    }
  }

  target {
    name           = "jumphost-target-conn"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"
    resource_arns  = ["arn:aws:ec2:${var.region}:${var.account_id}:instance/${var.jumphost_instance_id}"]
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "connection-exhaustion-lambda"
  })
}

# ============================================================================
# CloudWatch Alarms - Redis/Elasticache Stop Conditions
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "redis_cpu_stop" {
  count               = var.enable_redis_stress_alarms && var.redis_cluster_id != "" ? 1 : 0
  alarm_name          = "fis-stop-redis-cpu-${var.redis_cluster_id}"
  alarm_description   = "Stop condition for Redis FIS experiments - EngineCPUUtilization > 90% for 2 minutes"
  namespace           = "AWS/ElastiCache"
  metric_name         = "EngineCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  period              = 60
  evaluation_periods  = 2
  statistic           = "Average"

  dimensions = {
    CacheClusterId = var.redis_cluster_id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "redis_memory_stop" {
  count               = var.enable_redis_stress_alarms && var.redis_cluster_id != "" ? 1 : 0
  alarm_name          = "fis-stop-redis-memory-${var.redis_cluster_id}"
  alarm_description   = "Stop condition for Redis FIS experiments - FreeableMemory < 100MB"
  namespace           = "AWS/ElastiCache"
  metric_name         = "FreeableMemory"
  comparison_operator = "LessThanThreshold"
  threshold           = 104857600
  period              = 60
  evaluation_periods  = 2
  statistic           = "Minimum"

  dimensions = {
    CacheClusterId = var.redis_cluster_id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "redis_connections_stop" {
  count               = var.enable_redis_stress_alarms && var.redis_cluster_id != "" ? 1 : 0
  alarm_name          = "fis-stop-redis-connections-${var.redis_cluster_id}"
  alarm_description   = "Stop condition for Redis FIS experiments - CurrConnections > 64000"
  namespace           = "AWS/ElastiCache"
  metric_name         = "CurrConnections"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 64000
  period              = 60
  evaluation_periods  = 2
  statistic           = "Maximum"

  dimensions = {
    CacheClusterId = var.redis_cluster_id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "redis_replica_lag_stop" {
  count               = var.enable_redis_stress_alarms && var.redis_replication_group_id != "" ? 1 : 0
  alarm_name          = "fis-stop-redis-replica-lag-${var.redis_replication_group_id}"
  alarm_description   = "Stop condition for Redis FIS experiments - ReplicationLag > 60 seconds for 2 minutes"
  namespace           = "AWS/ElastiCache"
  metric_name         = "ReplicationLag"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 60
  period              = 60
  evaluation_periods  = 2
  statistic           = "Maximum"

  dimensions = {
    ReplicationGroupId = var.redis_replication_group_id
    NodeGroupId        = var.redis_node_group_id
  }

  tags = local.common_tags
}

# ============================================================================
# FIS Experiment Template 9: Redis CPU Stress via Lambda
# ============================================================================

resource "aws_fis_experiment_template" "redis_cpu_stress_lambda" {
  count       = var.enable_redis_stress_tests && var.jumphost_instance_id != "" && length(var.redis_stress_lambda_arns) > 0 ? 1 : 0
  description = "Trigger Redis CPU stress test Lambda via SSM on jump host in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  dynamic "stop_condition" {
    for_each = var.enable_redis_stress_alarms ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.redis_cpu_stop[0].arn
    }
  }

  action {
    name        = "redis-cpu-stress-via-lambda"
    action_id   = "aws:ssm:send-command"
    description = "Invoke Redis CPU stress Lambda function via SSM on jump host"

    parameter {
      key   = "duration"
      value = "PT${var.stress_duration_seconds / 60}M"
    }

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        commands = [
          "aws lambda invoke --function-name ${var.redis_stress_lambda_function_names["cpu_stress"]} --region ${var.region} --payload '{}' /tmp/redis-cpu-stress-output.json && cat /tmp/redis-cpu-stress-output.json"
        ]
      })
    }

    target {
      key   = "Instances"
      value = "jumphost-target-redis-cpu"
    }
  }

  target {
    name           = "jumphost-target-redis-cpu"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"
    resource_arns  = ["arn:aws:ec2:${var.region}:${var.account_id}:instance/${var.jumphost_instance_id}"]
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "redis-cpu-stress-lambda"
  })
}

# ============================================================================
# FIS Experiment Template 10: Redis Memory Stress via Lambda
# ============================================================================

resource "aws_fis_experiment_template" "redis_memory_stress_lambda" {
  count       = var.enable_redis_stress_tests && var.jumphost_instance_id != "" && length(var.redis_stress_lambda_arns) > 0 ? 1 : 0
  description = "Trigger Redis memory stress test Lambda via SSM on jump host in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  dynamic "stop_condition" {
    for_each = var.enable_redis_stress_alarms ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.redis_memory_stop[0].arn
    }
  }

  action {
    name        = "redis-memory-stress-via-lambda"
    action_id   = "aws:ssm:send-command"
    description = "Invoke Redis memory stress Lambda function via SSM on jump host"

    parameter {
      key   = "duration"
      value = "PT${var.stress_duration_seconds / 60}M"
    }

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        commands = [
          "aws lambda invoke --function-name ${var.redis_stress_lambda_function_names["memory_stress"]} --region ${var.region} --payload '{}' /tmp/redis-memory-stress-output.json && cat /tmp/redis-memory-stress-output.json"
        ]
      })
    }

    target {
      key   = "Instances"
      value = "jumphost-target-redis-memory"
    }
  }

  target {
    name           = "jumphost-target-redis-memory"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"
    resource_arns  = ["arn:aws:ec2:${var.region}:${var.account_id}:instance/${var.jumphost_instance_id}"]
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "redis-memory-stress-lambda"
  })
}

# ============================================================================
# FIS Experiment Template 11: Redis Connection Exhaustion via Lambda
# ============================================================================

resource "aws_fis_experiment_template" "redis_connection_exhaustion_lambda" {
  count       = var.enable_redis_stress_tests && var.jumphost_instance_id != "" && length(var.redis_stress_lambda_arns) > 0 ? 1 : 0
  description = "Trigger Redis connection exhaustion test Lambda via SSM on jump host in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  dynamic "stop_condition" {
    for_each = var.enable_redis_stress_alarms ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.redis_connections_stop[0].arn
    }
  }

  action {
    name        = "redis-conn-exhaustion-via-lambda"
    action_id   = "aws:ssm:send-command"
    description = "Invoke Redis connection exhaustion Lambda function via SSM on jump host"

    parameter {
      key   = "duration"
      value = "PT${var.stress_duration_seconds / 60}M"
    }

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        commands = [
          "aws lambda invoke --function-name ${var.redis_stress_lambda_function_names["connection_exhaustion"]} --region ${var.region} --payload '{}' /tmp/redis-conn-exhaust-output.json && cat /tmp/redis-conn-exhaust-output.json"
        ]
      })
    }

    target {
      key   = "Instances"
      value = "jumphost-target-redis-conn"
    }
  }

  target {
    name           = "jumphost-target-redis-conn"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"
    resource_arns  = ["arn:aws:ec2:${var.region}:${var.account_id}:instance/${var.jumphost_instance_id}"]
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "redis-connection-exhaustion-lambda"
  })
}

# ============================================================================
# FIS Experiment Template 12: Redis Replication Group Failover (Standalone)
# ============================================================================
# Triggers an ElastiCache TestFailover for the Redis replication group by
# invoking the failover Lambda via SSM on the jump host.

resource "aws_fis_experiment_template" "redis_failover" {
  count       = var.enable_redis_failover && var.jumphost_instance_id != "" && var.redis_failover_lambda_function_name != "" ? 1 : 0
  description = "Trigger ElastiCache Redis replication group failover (TestFailover) via Lambda on jump host in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  dynamic "stop_condition" {
    for_each = var.enable_redis_stress_alarms && var.redis_cluster_id != "" ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.redis_cpu_stop[0].arn
    }
  }

  dynamic "stop_condition" {
    for_each = var.enable_redis_stress_alarms && var.redis_cluster_id != "" ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.redis_memory_stop[0].arn
    }
  }

  dynamic "stop_condition" {
    for_each = var.enable_redis_stress_alarms && var.redis_cluster_id != "" ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.redis_connections_stop[0].arn
    }
  }

  dynamic "stop_condition" {
    for_each = var.enable_redis_stress_alarms && var.redis_replication_group_id != "" ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.redis_replica_lag_stop[0].arn
    }
  }

  action {
    name        = "redis-failover"
    action_id   = "aws:ssm:send-command"
    description = "Invoke Redis failover Lambda function via SSM on jump host"

    parameter {
      key   = "duration"
      value = "PT2M"
    }

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        commands = [
          "aws lambda invoke --function-name ${var.redis_failover_lambda_function_name} --region ${var.region} --payload '{}' /tmp/redis-failover-output.json && cat /tmp/redis-failover-output.json"
        ]
      })
    }

    target {
      key   = "Instances"
      value = "jumphost-target-redis-failover"
    }
  }

  target {
    name           = "jumphost-target-redis-failover"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"
    resource_arns  = ["arn:aws:ec2:${var.region}:${var.account_id}:instance/${var.jumphost_instance_id}"]
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "redis-failover"
  })
}

# ============================================================================
# FIS Experiment Template 13: Redis Failover Under CPU Stress
# ============================================================================
# CPU stress starts first (T=0, runs for stress_duration_seconds).
# After 2 minutes (wait action), the failover Lambda is invoked while the
# stress action is still running, simulating a failover under load.

resource "aws_fis_experiment_template" "redis_failover_under_stress" {
  count       = var.enable_redis_failover_under_stress && var.jumphost_instance_id != "" && var.redis_failover_lambda_function_name != "" && length(var.redis_stress_lambda_arns) > 0 ? 1 : 0
  description = "Redis failover under CPU stress: stress starts, waits 2 minutes, then triggers failover while stress continues in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  dynamic "stop_condition" {
    for_each = var.enable_redis_stress_alarms && var.redis_cluster_id != "" ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.redis_cpu_stop[0].arn
    }
  }

  dynamic "stop_condition" {
    for_each = var.enable_redis_stress_alarms && var.redis_cluster_id != "" ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.redis_memory_stop[0].arn
    }
  }

  dynamic "stop_condition" {
    for_each = var.enable_redis_stress_alarms && var.redis_cluster_id != "" ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.redis_connections_stop[0].arn
    }
  }

  dynamic "stop_condition" {
    for_each = var.enable_redis_stress_alarms && var.redis_replication_group_id != "" ? [1] : []
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.redis_replica_lag_stop[0].arn
    }
  }

  action {
    name        = "redis-stress"
    action_id   = "aws:ssm:send-command"
    description = "Invoke Redis CPU stress Lambda function via SSM on jump host"

    parameter {
      key   = "duration"
      value = "PT${var.stress_duration_seconds / 60}M"
    }

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        commands = [
          "aws lambda invoke --function-name ${var.redis_stress_lambda_function_names["cpu_stress"]} --region ${var.region} --payload '{}' /tmp/redis-failover-stress-output.json && cat /tmp/redis-failover-stress-output.json"
        ]
      })
    }

    target {
      key   = "Instances"
      value = "jumphost-target-redis-failover-stress"
    }
  }

  action {
    name        = "wait-for-stress"
    action_id   = "aws:fis:wait"
    start_after = ["redis-stress"]

    parameter {
      key   = "duration"
      value = "PT2M"
    }
  }

  action {
    name        = "redis-failover"
    action_id   = "aws:ssm:send-command"
    description = "Invoke Redis failover Lambda function via SSM on jump host while stress continues"
    start_after = ["wait-for-stress"]

    parameter {
      key   = "duration"
      value = "PT2M"
    }

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        commands = [
          "aws lambda invoke --function-name ${var.redis_failover_lambda_function_name} --region ${var.region} --payload '{}' /tmp/redis-failover-under-stress-output.json && cat /tmp/redis-failover-under-stress-output.json"
        ]
      })
    }

    target {
      key   = "Instances"
      value = "jumphost-target-redis-failover-stress"
    }
  }

  target {
    name           = "jumphost-target-redis-failover-stress"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"
    resource_arns  = ["arn:aws:ec2:${var.region}:${var.account_id}:instance/${var.jumphost_instance_id}"]
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "redis-failover-under-stress"
  })
}

# ============================================================================
# FIS Experiment Template: Network Latency Injection on EC2
# ============================================================================
# Uses aws:ssm:send-command with the AWS-published SSM document
# AWSFIS-Run-Network-Latency-Sources to inject network delay + jitter via
# Linux tc netem on target EC2 instances. Blast radius is instance-level
# (only targeted instances are affected, not the entire subnet).
# The SSM document has built-in rollback via atd + signal handlers.

resource "aws_fis_experiment_template" "network_latency" {
  for_each    = var.enable_network_latency ? local.network_latency_template_keys : toset([])
  description = local.network_latency_use_service_names ? "Inject network latency (${var.network_latency_delay_ms}ms ± ${var.network_latency_jitter_ms}ms jitter) on ${each.value} EC2 instances in ${var.environment}" : "Inject network latency (${var.network_latency_delay_ms}ms ± ${var.network_latency_jitter_ms}ms jitter) on EC2 instances in ${var.environment}"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  action {
    name        = "network-latency"
    action_id   = "aws:ssm:send-command"
    description = "Inject ${var.network_latency_delay_ms}ms latency with ${var.network_latency_jitter_ms}ms jitter via tc netem on ${var.network_latency_traffic_type} traffic to ${var.network_latency_sources}"

    parameter {
      key   = "duration"
      value = var.network_latency_duration
    }

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:${var.region}::document/AWSFIS-Run-Network-Latency-Sources"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        DelayMilliseconds   = tostring(var.network_latency_delay_ms)
        JitterMilliseconds  = tostring(var.network_latency_jitter_ms)
        Sources             = var.network_latency_sources
        Interface           = var.network_latency_interface
        TrafficType         = var.network_latency_traffic_type
        FlowsPercent        = tostring(var.network_latency_flows_percent)
        DurationSeconds     = tostring(var.network_latency_duration_seconds)
        InstallDependencies = var.network_latency_install_dependencies ? "True" : "False"
      })
    }

    target {
      key   = "Instances"
      value = "network-latency-target"
    }
  }

  target {
    name           = "network-latency-target"
    resource_type  = "aws:ec2:instance"
    selection_mode = "ALL"

    resource_arns = local.network_latency_use_service_names || length(var.network_latency_target_resource_tags) > 0 ? null : var.network_latency_target_instance_arns

    dynamic "resource_tag" {
      for_each = local.network_latency_use_service_names ? local.network_latency_service_tags[each.value] : var.network_latency_target_resource_tags
      content {
        key   = resource_tag.key
        value = resource_tag.value
      }
    }
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(
    local.common_tags,
    { Experiment = "network-latency" },
    local.network_latency_use_service_names ? { Service = each.value } : {}
  )
}

# ============================================================================
# FIS Experiment Template: Simple Network Latency on EC2
# ============================================================================
# Uses AWSFIS-Run-Network-Latency-Sources — same SSM doc as the advanced
# variant but with fewer knobs (no jitter, no traffic_type, no flows_percent).
# Sources defaults to ALL (all traffic). Set to specific IPs/CIDRs/domains
# to target only that traffic. Reuses network_latency_target_instance_arns
# and network_latency_duration* variables from the -Sources template.

resource "aws_fis_experiment_template" "network_latency_simple" {
  for_each    = var.enable_network_latency_simple ? local.network_latency_template_keys : toset([])
  description = local.network_latency_use_service_names ? "Inject ${var.network_latency_simple_delay_ms}ms network latency on ${each.value} EC2 instances in ${var.environment} (sources: ${var.network_latency_simple_sources})" : "Inject ${var.network_latency_simple_delay_ms}ms network latency on EC2 instances in ${var.environment} (sources: ${var.network_latency_simple_sources})"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  action {
    name        = "network-latency-simple"
    action_id   = "aws:ssm:send-command"
    description = "Inject ${var.network_latency_simple_delay_ms}ms latency via tc netem on ${var.network_latency_simple_sources} traffic on interface ${var.network_latency_simple_interface}"

    parameter {
      key   = "duration"
      value = var.network_latency_duration
    }

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:${var.region}::document/AWSFIS-Run-Network-Latency-Sources"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        DelayMilliseconds   = tostring(var.network_latency_simple_delay_ms)
        Sources             = var.network_latency_simple_sources
        Interface           = var.network_latency_simple_interface
        DurationSeconds     = tostring(var.network_latency_duration_seconds)
        InstallDependencies = var.network_latency_install_dependencies ? "True" : "False"
      })
    }

    target {
      key   = "Instances"
      value = "network-latency-simple-target"
    }
  }

  target {
    name           = "network-latency-simple-target"
    resource_type  = "aws:ec2:instance"
    selection_mode = "ALL"

    resource_arns = local.network_latency_use_service_names || length(var.network_latency_target_resource_tags) > 0 ? null : var.network_latency_target_instance_arns

    dynamic "resource_tag" {
      for_each = local.network_latency_use_service_names ? local.network_latency_service_tags[each.value] : var.network_latency_target_resource_tags
      content {
        key   = resource_tag.key
        value = resource_tag.value
      }
    }
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(
    local.common_tags,
    { Experiment = "network-latency-simple" },
    local.network_latency_use_service_names ? { Service = each.value } : {}
  )
}

# ============================================================================
# FIS Experiment Template: EC2 Instance Termination
# ============================================================================
# Uses aws:ec2:terminate-instances — a native FIS action that permanently
# terminates the targeted EC2 instances. No duration parameter needed;
# the action completes once instances are terminated.
# ⚠️ DESTRUCTIVE: Instances are permanently destroyed. Only target
# disposable/test instances. Ensure ASG self-healing or manual recreation
# is in place before enabling.

resource "aws_fis_experiment_template" "ec2_termination" {
  count       = var.enable_ec2_termination && length(var.ec2_termination_target_instance_arns) > 0 ? 1 : 0
  description = "Terminate EC2 instances in ${var.environment} to test instance loss resilience"
  role_arn    = aws_iam_role.fis_execution.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
  }

  action {
    name        = "terminate-instances"
    action_id   = "aws:ec2:terminate-instances"
    description = "Permanently terminate targeted EC2 instances"

    target {
      key   = "Instances"
      value = "ec2-termination-target"
    }
  }

  target {
    name           = "ec2-termination-target"
    resource_type  = "aws:ec2:instance"
    selection_mode = "ALL"
    resource_arns  = var.ec2_termination_target_instance_arns
  }

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "skip"
  }

  tags = merge(local.common_tags, {
    Experiment = "ec2-termination"
  })
}
