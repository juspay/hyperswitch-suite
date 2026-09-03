include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/composition/jump-host"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id                = "vpc-XXXXXXXXXXXXXXXXX"
    management_subnet_ids = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-YYYYYYYYYYYYYYYYY", "subnet-ZZZZZZZZZZZZZZZZZ"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  vpc_id    = dependency.vpc.outputs.vpc_id
  subnet_id = dependency.vpc.outputs.management_subnet_ids[0]

  ami_id           = "ami-XXXXXXXXXXXXXXXXX"
  instance_type    = "t3.medium"
  root_volume_size = 20
  root_volume_type = "gp3"

  log_retention_days = 30

  enable_migration_mode = false

  tags = {
    Environment = "development"
    Project     = "hyperswitch"
    ManagedBy   = "terraform-IaC"
    Region      = "eu-central-1"
  }
}
