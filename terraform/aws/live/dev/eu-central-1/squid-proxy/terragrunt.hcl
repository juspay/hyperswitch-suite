include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/composition/squid-proxy"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id                    = "vpc-XXXXXXXXXXXXXXXXX"
    outgoing_proxy_subnet_ids = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-YYYYYYYYYYYYYYYYY", "subnet-ZZZZZZZZZZZZZZZZZ"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  environment  = include.root.locals.environment.full
  region       = include.root.locals.region
  project_name = include.root.locals.project_name

  name_override = "squid"

  vpc_id           = dependency.vpc.outputs.vpc_id
  proxy_subnet_ids = dependency.vpc.outputs.outgoing_proxy_subnet_ids
  lb_subnet_ids    = dependency.vpc.outputs.outgoing_proxy_subnet_ids

  squid_port = 3128

  use_existing_launch_template = false

  ami_id        = "ami-XXXXXXXXXXXXXXXXX"
  instance_type = "t3.small"

  generate_ssh_key = true
  key_name         = null

  custom_userdata = file("${get_terragrunt_dir()}/templates/userdata.sh")

  create_logs_bucket = true
  logs_bucket_name   = ""
  logs_bucket_arn    = ""

  create_config_bucket = true
  config_bucket_name   = ""
  config_bucket_arn    = ""

  s3_config_path_prefix    = "squid"
  upload_config_to_s3      = true
  config_files_source_path = "${get_terragrunt_dir()}/config"

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  enable_detailed_monitoring = false
  configure_root_volume      = true
  root_volume_size           = 20
  root_volume_type           = "gp3"

  create_nlb               = true
  existing_lb_arn          = null
  existing_lb_listener_arn = null

  create_iam_role         = true
  create_instance_profile = true

  enable_tcp_listener = true
  tcp_listener_port   = 80
  enable_tls_listener = false
  tls_listener_port   = 443
  tls_certificate_arn = null
  tls_ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  tls_alpn_policy     = "None"

  enable_instance_refresh = true
  instance_refresh_preferences = {
    min_healthy_percentage       = 50
    instance_warmup              = 300
    max_healthy_percentage       = 100
    checkpoint_percentages       = [50]
    checkpoint_delay             = 300
    scale_in_protected_instances = "Ignore"
    standby_instances            = "Ignore"
  }
  instance_refresh_triggers = []

  enable_autoscaling = true
  scaling_policies = {
    cpu_target_tracking = {
      enabled      = true
      target_value = 70.0
    }
    memory_target_tracking = {
      enabled      = false
      target_value = 70.0
    }
  }

  enable_spot_instances     = false
  spot_instance_percentage  = 50
  on_demand_base_capacity   = 1
  spot_allocation_strategy  = "capacity-optimized"
  enable_capacity_rebalance = false

  tags = {
    Environment = "development"
    Project     = "hyperswitch"
    ManagedBy   = "terraform-IaC"
    Region      = "eu-central-1"
  }
}
