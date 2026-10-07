include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/clickhouse?ref=clickhouse-v0.1.4"
}

dependency "vpc" {
  config_path = try(values.vpc_config_path, "../../vpc-network")

  mock_outputs = {
    vpc_id                         = "vpc-12345678"
    data_stack_subnet_ids          = ["subnet-12345678", "subnet-12345679"]
    vpc_endpoint_security_group_id = "sg-12345678"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {

  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name

  # Network Configuration
  vpc_id                         = dependency.vpc.outputs.vpc_id
  keeper_subnet_id               = dependency.vpc.outputs.data_stack_subnet_ids[0]
  server_subnet_id               = dependency.vpc.outputs.data_stack_subnet_ids[0]
  vpc_endpoint_security_group_id = dependency.vpc.outputs.vpc_endpoint_security_group_id

  # Keeper Configuration — no keeper cluster needed outside prod.
  keeper_count = try(values.keeper_count, include.root.locals.environment.full == "prod" ? 3 : 1)

  # Server Configuration — single node outside prod.
  server_count = try(values.server_count, include.root.locals.environment.full == "prod" ? 2 : 1)

  # Instance Configuration
  keeper_ami_id = try(values.keeper_ami_id, null)
  server_ami_id = try(values.server_ami_id, null)

  keeper_instance_type = try(values.keeper_instance_type, "c7g.medium")
  server_instance_type = try(values.server_instance_type, "r7g.large")

  # Storage Configuration
  keeper_root_volume_size  = try(values.keeper_root_volume_size, 33)
  keeper_root_volume_type  = try(values.keeper_root_volume_type, "gp3")
  keeper_data_volume_size  = try(values.keeper_data_volume_size, 30)
  keeper_data_volume_type  = try(values.keeper_data_volume_type, "gp3")
  keeper_data2_volume_size = try(values.keeper_data2_volume_size, 10)
  keeper_data2_volume_type = try(values.keeper_data2_volume_type, "gp3")

  server_root_volume_size  = try(values.server_root_volume_size, 50)
  server_root_volume_type  = try(values.server_root_volume_type, "gp3")
  server_data_volume_size  = try(values.server_data_volume_size, 700)
  server_data_volume_type  = try(values.server_data_volume_type, "gp3")
  server_data2_volume_size = try(values.server_data2_volume_size, 500)
  server_data2_volume_type = try(values.server_data2_volume_type, "gp3")

  # Load Balancer Configuration
  clickhouse_port = 8123
  alb_subnet_ids  = dependency.vpc.outputs.data_stack_subnet_ids

  alb_listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
    }
  }

  # IAM Configuration
  iam_inline_policies = {
    clickhouse-ec2-policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = "ec2:*"
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = "autoscaling:*"
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = "iam:CreateServiceLinkedRole"
          Resource = "*"
          Condition = {
            StringEquals = {
              "iam:AWSServiceName" = [
                "autoscaling.amazonaws.com",
                "ec2scheduled.amazonaws.com"
              ]
            }
          }
        },
        {
          Action   = "sts:AssumeRole"
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  iam_managed_policy_arns = []

  # User Data Templates
  keeper_user_data_template = "${get_terragrunt_dir()}/templates/keeper-userdata.json"
  server_user_data_template = "${get_terragrunt_dir()}/templates/server-userdata.json"

  # SSH Key Configuration
  # Auto-generate SSH key pair and store private key in SSM Parameter Store
  create_key_pair = true

  # Metadata Options
  # Allow IMDSv1 for compatibility
  metadata_http_tokens = "optional"

  # Tags
  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
    Component   = "clickhouse"
  }

}
