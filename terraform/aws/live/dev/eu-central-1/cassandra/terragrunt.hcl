include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../..//modules/composition/cassandra"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id                = "vpc-XXXXXXXXXXXXXXXXX"
    data_stack_subnet_ids = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-YYYYYYYYYYYYYYYYY", "subnet-ZZZZZZZZZZZZZZZZZ"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  vpc_id    = dependency.vpc.outputs.vpc_id
  subnet_id = dependency.vpc.outputs.data_stack_subnet_ids[0]

  cluster_name       = "cassandra-hyperswitch"
  node_count         = 3
  replication_factor = 3
  idle_timeout       = "3600000ms"

  default_config_path = "ReadWriteHeavy"

  seed_discovery_lambda_source = "file://./index.mjs"
  api_gateway_vpce_id          = "vpce-XXXXXXXXXXXXXXXXX"

  ami_id          = "ami-XXXXXXXXXXXXXXXXX"
  instance_type   = "m7g.large"
  create_key_pair = true
  public_key      = null

  ebs_volume_size = 100
  ebs_volume_type = "gp3"

  cassandra_ports = {}

  log_retention_days = 30

  tags = {
    Environment = "development"
    Project     = "hyperswitch"
    Component   = "cassandra"
    ManagedBy   = "terraform-IaC"
    Region      = "eu-central-1"
  }
}
