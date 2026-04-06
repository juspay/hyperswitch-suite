provider "aws" {
  region = var.region
}

module "kafka" {
  source = "../../../../modules/composition/kafka"

  environment  = var.environment
  project_name = var.project_name

  vpc_id               = var.vpc_id
  broker_subnet_id     = var.broker_subnet_id
  controller_subnet_id = var.controller_subnet_id

  broker_count = var.broker_count

  broker_ami_id           = var.broker_ami_id
  broker_instance_type    = var.broker_instance_type
  broker_root_volume_size = var.broker_root_volume_size
  broker_root_volume_type = var.broker_root_volume_type
  broker_data_volume_size = var.broker_data_volume_size
  broker_data_volume_type = var.broker_data_volume_type
  broker_data_device_name = var.broker_data_device_name

  controller_ami_id                = var.controller_ami_id
  controller_instance_type         = var.controller_instance_type
  controller_root_volume_size      = var.controller_root_volume_size
  controller_root_volume_type      = var.controller_root_volume_type
  controller_metadata_volume_size  = var.controller_metadata_volume_size
  controller_metadata_volume_type  = var.controller_metadata_volume_type
  controller_metadata_device_name  = var.controller_metadata_device_name

  create_key_pair = var.create_key_pair
  public_key      = var.public_key

  tags = var.common_tags
}
