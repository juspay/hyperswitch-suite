locals {
  name_prefix = "${var.environment}-${var.project_name}-cassandra"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "cassandra"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  # Cluster tags used for seed discovery (from variables)
  cluster_tag_name  = var.cluster_tag_name
  cluster_tag_value = var.cluster_tag_value
  eni_tag_name      = var.eni_tag_name
  eni_tag_value     = var.eni_tag_value

  # Key pair logic (same pattern as locker)
  key_name      = var.create_key_pair ? aws_key_pair.cassandra[0].key_name : var.key_name
  key_pair_name = var.key_name != null ? var.key_name : "${local.name_prefix}-key"

  # Subnet
  cassandra_subnet_id = var.subnet_id

  # Seed discovery - create if not provided and enabled
  create_seed_discovery = var.create_seed_discovery && var.seeds_url == null

  # Seed discovery Lambda source path - must be provided when create_seed_discovery is true
  # The path to the Lambda source file (e.g., "/path/to/index.mjs")

  # User data configuration passed to EC2 instances
  user_data_config = jsonencode({
    seedsUrl          = local.create_seed_discovery ? "${module.seed_discovery_api[0].invoke_url}/CassandraSeedNode" : var.seeds_url
    clusterTagName    = local.cluster_tag_name
    clusterTagValue   = local.cluster_tag_value
    eniTagName        = local.eni_tag_name
    eniTagValue       = local.eni_tag_value
    clusterName       = var.cluster_name
    replicationFactor = tostring(var.replication_factor)
    idleTimeout       = var.idle_timeout
    defaultConfigPath = var.default_config_path
  })
}
