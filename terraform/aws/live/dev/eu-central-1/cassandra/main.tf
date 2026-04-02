provider "aws" {
  region = var.region
}

module "cassandra" {
  source = "../../../../modules/composition/cassandra"

  environment  = var.environment
  project_name = var.project_name
  region       = var.region

  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id

  cluster_name        = var.cluster_name
  node_count          = var.node_count
  replication_factor  = var.replication_factor
  idle_timeout        = var.idle_timeout
  default_config_path = var.default_config_path

  seed_discovery_lambda_source = var.seed_discovery_lambda_source
  api_gateway_vpce_id          = var.api_gateway_vpce_id

  ami_id          = var.ami_id
  instance_type   = var.instance_type
  create_key_pair = var.create_key_pair
  public_key      = var.public_key
  ebs_volume_size = var.ebs_volume_size
  ebs_volume_type = var.ebs_volume_type

  cassandra_ports = var.cassandra_ports

  log_retention_days = var.log_retention_days

  tags = var.common_tags
}
