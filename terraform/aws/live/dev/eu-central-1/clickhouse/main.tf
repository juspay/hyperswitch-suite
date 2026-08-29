provider "aws" {
  region = var.region
}

module "clickhouse" {
  source = "../../../../modules/composition/clickhouse"

  environment  = var.environment
  project_name = var.project_name

  vpc_id            = var.vpc_id
  keeper_subnet_id  = var.keeper_subnet_id
  server_subnet_id  = var.server_subnet_id

  keeper_count                = var.keeper_count
  keeper_ami_id               = var.keeper_ami_id
  keeper_instance_type        = var.keeper_instance_type
  keeper_root_volume_size     = var.keeper_root_volume_size
  keeper_root_volume_type     = var.keeper_root_volume_type
  keeper_data_volume_size     = var.keeper_data_volume_size
  keeper_data_volume_type     = var.keeper_data_volume_type
  keeper_data_device_name     = var.keeper_data_device_name

  server_count                = var.server_count
  server_ami_id               = var.server_ami_id
  server_instance_type        = var.server_instance_type
  server_root_volume_size     = var.server_root_volume_size
  server_root_volume_type     = var.server_root_volume_type
  server_data_volume_size     = var.server_data_volume_size
  server_data_volume_type     = var.server_data_volume_type
  server_data_device_name     = var.server_data_device_name

  create_key_pair = var.create_key_pair
  public_key      = var.public_key

  tags = var.common_tags
}
