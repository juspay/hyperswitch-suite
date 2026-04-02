locals {
  name_prefix = "${var.environment}-${var.project_name}-clickhouse"
  alb_name_prefix = "${var.environment}-ckh"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "clickhouse"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  # Key pair logic (same pattern as kafka/cassandra)
  key_name      = var.create_key_pair ? aws_key_pair.clickhouse[0].key_name : var.key_name
  key_pair_name = var.key_name != null ? var.key_name : "${local.name_prefix}-key"

  # Security group references (handle conditional creation)
  keeper_sg_id = var.keeper_count > 0 ? aws_security_group.keeper[0].id : null

  # Build keeper IP list from ENI private IPs
  keeper_ips = var.keeper_count > 0 ? [for i in range(var.keeper_count) : aws_network_interface.keeper[i].private_ip] : []

  # Build server IP list from ENI private IPs
  server_ips = [for i in range(var.server_count) : aws_network_interface.server[i].private_ip]

  # Build shard configuration - one shard with all servers
  shard_config = [local.server_ips]

  # Default IAM inline policy (Kafka-like permissions)
  default_inline_policies = {
    clickhouse-ec2-policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = "ec2:*"
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = "autoscaling:*"
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = "iam:CreateServiceLinkedRole"
          Resource = "*"
          Condition = {
            StringEquals = {
              "iam:AWSServiceName" = [
                "autoscaling.amazonaws.com",
                "ec2scheduled.amazonaws.com"
              ]
            }
          }
        },
        {
          Action   = "sts:AssumeRole"
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  inline_policies = length(var.iam_inline_policies) > 0 ? var.iam_inline_policies : local.default_inline_policies
  managed_policies = var.iam_managed_policy_arns

  # Keeper user data - use template if provided, else use default
  default_keeper_user_data = jsonencode({
    type = "keeper"
  })

  keeper_user_data = var.keeper_user_data_template != null ? replace(
    replace(
      file(var.keeper_user_data_template),
      "{{keeper_ips}}", jsonencode(local.keeper_ips)
    ),
    "{{server_ips}}", jsonencode(local.shard_config)
  ) : local.default_keeper_user_data

  # Server user data - use template if provided, else use default
  default_server_user_data = jsonencode({
    type = "server"
  })

  server_user_data = var.server_user_data_template != null ? replace(
    replace(
      file(var.server_user_data_template),
      "{{keeper_ips}}", jsonencode(local.keeper_ips)
    ),
    "{{server_ips}}", jsonencode(local.shard_config)
  ) : local.default_server_user_data
}