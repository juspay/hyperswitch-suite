include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/kafka?ref=kafka-v0.1.3"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id                         = "vpc-12345678"
    data_stack_subnet_ids          = ["subnet-12345678"]
    vpc_endpoint_security_group_id = "sg-vpc-endpoint"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name

  # Network Configuration
  vpc_id                         = dependency.vpc.outputs.vpc_id
  broker_subnet_id               = dependency.vpc.outputs.data_stack_subnet_ids[0]
  controller_subnet_id           = dependency.vpc.outputs.data_stack_subnet_ids[0]
  vpc_endpoint_security_group_id = dependency.vpc.outputs.vpc_endpoint_security_group_id

  # Cluster Configuration
  broker_count = 3

  # Instance Configuration — cost-optimized for passive/DR
  broker_ami_id     = try(values.broker_ami_id, null)
  controller_ami_id = try(values.controller_ami_id, null)

  broker_instance_type     = "t4g.medium"
  controller_instance_type = "t4g.medium"

  # Storage Configuration — smaller for passive/DR
  broker_root_volume_size         = 30
  broker_root_volume_type         = "gp3"
  broker_data_volume_size         = 30
  broker_data_volume_type         = "gp3"
  controller_root_volume_size     = 30
  controller_root_volume_type     = "gp3"
  controller_metadata_volume_size = 10
  controller_metadata_volume_type = "gp3"

  # SSH Key Configuration
  create_key_pair = true

  # Metadata Options
  metadata_http_tokens = "optional"

  # Tags
  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
    Component   = "kafka"
  }
}
