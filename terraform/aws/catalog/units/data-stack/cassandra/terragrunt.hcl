include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/cassandra?ref=cassandra-v0.1.1"
}

dependency "vpc" {
  config_path = try(values.vpc_config_path, "../../vpc-network")

  mock_outputs = {
    vpc_id                         = "vpc-12345678"
    data_stack_subnet_ids          = ["subnet-12345678"]
    vpc_endpoint_security_group_id = "sg-12345678"
    interface_vpc_endpoint_ids = {
      execute_api = "vpce-12345678"
      ec2         = "vpce-ec212345"
      ecr_api     = "vpce-ecr12345"
      logs        = "vpce-logs1234"
    }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {

  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  # Network Configuration
  vpc_id    = dependency.vpc.outputs.vpc_id
  subnet_id = dependency.vpc.outputs.data_stack_subnet_ids[0]

  # Cluster Configuration
  cluster_name        = try(values.cluster_name, "cassandra-hyperswitch")
  node_count          = try(values.node_count, include.root.locals.environment.full == "prod" ? 5 : 3)
  replication_factor  = try(values.replication_factor, 3)
  idle_timeout        = "3600000ms"
  default_config_path = "ReadWriteHeavy"

  # Seed Discovery Configuration
  # The seed discovery Lambda and API Gateway will be created automatically
  seed_discovery_lambda_source_path = "${get_terragrunt_dir()}/lambda/index.mjs"
  api_gateway_vpce_id               = dependency.vpc.outputs.interface_vpc_endpoint_ids["execute_api"]
  vpc_endpoint_security_group_id    = dependency.vpc.outputs.vpc_endpoint_security_group_id

  # Instance Configuration
  ami_id        = try(values.ami_id, null)
  instance_type = try(values.instance_type, "m7g.large")

  # Storage Configuration
  ebs_volume_size = try(values.ebs_volume_size, 100)
  ebs_volume_type = try(values.ebs_volume_type, "gp3")

  # SSH Key Configuration
  # Auto-generate SSH key pair and store private key in SSM Parameter Store
  create_key_pair = true

  # Logging Configuration
  log_retention_days = try(values.log_retention_days, 30)

  # IMDSv2 Configuration
  metadata_http_tokens = "optional"

  # Tags
  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
    Component   = "cassandra"
  }

}
