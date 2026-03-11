locals {
  name_prefix = "${var.environment}-${var.project_name}-kafka"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "kafka"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  # Key pair logic
  key_name      = var.create_key_pair ? aws_key_pair.kafka[0].key_name : var.key_name
  key_pair_name = var.key_name != null ? var.key_name : "${local.name_prefix}-key"

  # Broker user data - use override if provided, else use default JSON
  broker_user_data = var.broker_user_data_override != null ? var.broker_user_data_override : jsonencode({
    type      = "broker"
    extraConf = var.broker_extra_config
  })

  # Controller user data - use override if provided, else use default JSON
  controller_user_data = var.controller_user_data_override != null ? var.controller_user_data_override : jsonencode({
    type = "controller"
  })
}