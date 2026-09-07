include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  extra_atlantis_dependencies = [
    "config/**",
    "templates/userdata.sh"
  ]
}

dependency "vpc_network" {
  config_path = "../vpc-network"

  mock_outputs = {
    outgoing_proxy_subnet_ids = ["mock-outgoing_proxy_subnet_ids"]
    vpc_id                    = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/squid-proxy?ref=squid-proxy-v0.1.4"
}

inputs = {

  environment  = include.root.locals.environment.full
  region       = include.root.locals.region
  project_name = include.root.locals.project_name

  vpc_id = dependency.vpc_network.outputs.vpc_id

  proxy_subnet_ids = dependency.vpc_network.outputs.outgoing_proxy_subnet_ids
  lb_subnet_ids    = dependency.vpc_network.outputs.outgoing_proxy_subnet_ids

  squid_port    = 3128
  ami_id        = values.ami_id
  instance_type = "t3.medium"

  generate_ssh_key = true

  # Wazuh enrollment and sudo users are environment-specific; supplied via stack values.
  custom_userdata = replace(replace(replace(replace(replace(replace(
    file("${get_terragrunt_dir()}/templates/userdata.sh"),
    "{{update-wazuh}}", try(values.wazuh_manager_addr, "") != "" ? "Enable" : "Disable"),
    "{{wazuh-manager-addr}}", try(values.wazuh_manager_addr, "NA")),
    "{{wazuh-worker-addr}}", try(values.wazuh_worker_addr, "NA")),
    "{{wazuh-group}}", try(values.wazuh_group, "NA")),
    "{{wazuh-tag}}", try(values.wazuh_tag, "NA")),
  "{{sudo-user-list}}", try(values.sudo_user_list, "ubuntu"))

  create_logs_bucket = true

  create_config_bucket = true

  upload_config_to_s3 = true
  config_files = {
    "allowedlist.txt" = "${get_repo_root()}/whitelisted-domains/${include.root.locals.environment.full}-allowedlist.txt"
    "squid.conf"      = "${get_terragrunt_dir()}/config/squid.conf"
    "vector.toml"     = "${get_terragrunt_dir()}/config/vector.toml"
  }

  min_size         = 1
  max_size         = 6
  desired_capacity = 1

  enable_detailed_monitoring = true
  configure_root_volume      = true
  root_volume_size           = 30
  root_volume_type           = "gp3"

  create_nlb = true

  enable_tcp_listener = true
  tcp_listener_port   = 80
  enable_tls_listener = false
  tls_listener_port   = 443

  enable_instance_refresh = true
  instance_refresh_preferences = {
    min_healthy_percentage       = 50
    instance_warmup              = 60
    max_healthy_percentage       = 150
    checkpoint_percentages       = []
    checkpoint_delay             = 300
    scale_in_protected_instances = "Ignore"
    standby_instances            = "Ignore"
  }
  instance_refresh_triggers = ["launch_template"]

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

  create_iam_role = true

  create_instance_profile = true

  additional_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }

}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.30.0"
    }
  }
}
EOF
}
