include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/composition/envoy-proxy"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id                       = "vpc-XXXXXXXXXXXXXXXXX"
    incoming_envoy_subnet_ids    = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-YYYYYYYYYYYYYYYYY", "subnet-ZZZZZZZZZZZZZZZZZ"]
    external_incoming_subnet_ids = ["subnet-AAAAAAAAAAAAAAAAA", "subnet-BBBBBBBBBBBBBBBBB", "subnet-CCCCCCCCCCCCCCCCC"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name = "dev-hyperswitch-cluster-01"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name

  vpc_id           = dependency.vpc.outputs.vpc_id
  proxy_subnet_ids = dependency.vpc.outputs.incoming_envoy_subnet_ids
  lb_subnet_ids    = dependency.vpc.outputs.external_incoming_subnet_ids

  eks_cluster_name = dependency.eks.outputs.cluster_name

  launch_template = {
    create        = true
    ami_id        = "ami-XXXXXXXXXXXXXXXXX"
    instance_type = "t3.small"

    update_default_version = true

    ebs_optimized           = false
    enable_ebs_block_device = true
    ebs_encrypted           = false
    root_volume_size        = 20
    root_volume_type        = "gp3"

    imds_http_endpoint               = "enabled"
    imds_http_tokens                 = "optional"
    imds_http_put_response_hop_limit = 1
    imds_instance_metadata_tags      = "enabled"

    enable_detailed_monitoring = true
  }

  deployments = {
    stable = {
      weight                  = 100
      desired_capacity        = 1
      launch_template_version = "$Latest"
    }
  }

  alb_http_listener_port  = 80
  alb_https_listener_port = 443
  envoy_traffic_port      = 80
  envoy_upstream_port     = 80

  generate_ssh_key = true
  key_name         = null

  custom_userdata       = file("${get_terragrunt_dir()}/templates/userdata.sh")
  envoy_config_template = file("${get_terragrunt_dir()}/config/envoy.yaml")

  hyperswitch_cloudfront_dns = "dXXXXXXXXXXXXX.cloudfront.net"
  internal_loadbalancer_dns  = "internal-alb-XXXXXXXXXX.eu-central-1.elb.amazonaws.com"

  create_logs_bucket = true
  logs_bucket_name   = ""
  logs_bucket_arn    = ""

  create_config_bucket     = true
  config_bucket_name       = ""
  config_bucket_arn        = ""
  upload_config_to_s3      = true
  config_files_source_path = "${get_terragrunt_dir()}/config"
  envoy_config_filename    = "envoy.yaml"

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  create_lb                     = true
  lb_internal                   = false
  create_target_group           = true
  existing_tg_arn               = null
  existing_lb_arn               = null
  existing_lb_security_group_id = null

  enable_https_listener         = false
  ssl_certificate_arn           = null
  ssl_policy                    = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  enable_http_to_https_redirect = false
  additional_certificate_arns   = []

  listener_rules = []

  enable_waf      = false
  waf_web_acl_arn = null

  target_group_protocol             = "HTTP"
  target_group_deregistration_delay = 30

  health_check = {
    enabled             = true
    port                = 80
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lb_ingress_rules = []
  lb_egress_rules  = []

  s3_vpc_endpoint_prefix_list_id = null

  enable_spot_instances     = false
  spot_instance_percentage  = 50
  on_demand_base_capacity   = 1
  spot_allocation_strategy  = "capacity-optimized"
  enable_capacity_rebalance = false

  termination_policies  = ["OldestLaunchTemplate", "OldestInstance", "Default"]
  max_instance_lifetime = 0

  create_iam_role                    = true
  existing_iam_role_name             = null
  create_instance_profile            = true
  existing_iam_instance_profile_name = null
  additional_policy_arns             = []

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

  tags = {
    Environment = "development"
    Project     = "hyperswitch"
    ManagedBy   = "terraform-IaC"
    Region      = "eu-central-1"
  }
}
