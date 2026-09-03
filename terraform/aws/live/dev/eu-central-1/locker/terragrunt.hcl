include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/composition/locker"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id                   = "vpc-XXXXXXXXXXXXXXXXX"
    locker_server_subnet_ids = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-YYYYYYYYYYYYYYYYY", "subnet-ZZZZZZZZZZZZZZZZZ"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  vpc_id            = dependency.vpc.outputs.vpc_id
  locker_subnet_ids = dependency.vpc.outputs.locker_server_subnet_ids
  alb_subnet_ids    = dependency.vpc.outputs.locker_server_subnet_ids

  ami_id         = "ami-XXXXXXXXXXXXXXXXX"
  instance_type  = "t3.medium"
  instance_count = 1

  key_name        = null
  create_key_pair = true
  public_key      = null

  locker_port = 8080

  alb_listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
    }
  }

  enable_alb_deletion_protection = false

  create_locker_database = false

  log_retention_days = 30

  tags = {
    Environment = "development"
    Project     = "hyperswitch"
    Component   = "locker"
    ManagedBy   = "terraform-IaC"
    Region      = "eu-central-1"
  }
}
