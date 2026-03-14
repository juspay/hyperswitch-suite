locals {
  name_prefix = "${var.environment}-${var.project_name}-clickhouse"

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

  # Build keeper IP list from ENI private IPs
  keeper_ips = var.keeper_count > 0 ? [for i in range(var.keeper_count) : aws_network_interface.keeper[i].private_ip] : []

  # Build server IP list from ENI private IPs
  server_ips = [for i in range(var.server_count) : aws_network_interface.server[i].private_ip]

  # Build shard configuration - one shard with all servers
  shard_config = [local.server_ips]

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
    type        = "server"
    clusterName = var.cluster_name
  })

  server_user_data = var.server_user_data_template != null ? replace(
    replace(
      file(var.server_user_data_template),
      "{{keeper_ips}}", jsonencode(local.keeper_ips)
    ),
    "{{server_ips}}", jsonencode(local.shard_config)
  ) : local.default_server_user_data
}