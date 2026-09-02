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

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    external_incoming_subnet_ids = ["mock-external_incoming_subnet_ids"]
    incoming_envoy_subnet_ids    = ["mock-incoming_envoy_subnet_ids"]
    vpc_id                       = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "acm" {
  config_path = "../acm"

  mock_outputs = {
    certificate_arns = {
      envoy-alb = "envoy-alb-mock-arn"
      integ-alb = "integ-alb-mock-arn"
    }
    certificate_statuses = {
      envoy-alb = "PENDING_VALIDATION"
    }
  }

  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/envoy-proxy?ref=envoy-v0.3.2"
}

# ---------------------------------------------------------------------------
# Rendered config files. The environment-specific log-sink endpoint comes from
# stack values; the rendered copies land in the terraform working directory
# and are uploaded to S3 by the module (config_files_source_path below).
# ---------------------------------------------------------------------------
generate "vector_toml" {
  path      = "generated-config/vector.toml"
  if_exists = "overwrite"
  contents = replace(replace(
    file("${get_terragrunt_dir()}/config/vector.toml"),
    "{{opensearch-endpoint}}", try(values.opensearch_endpoint, "https://opensearch.invalid")),
  "{{opensearch-region}}", try(values.opensearch_region, "us-east-1"))
}

generate "envoy_yaml" {
  path      = "generated-config/envoy.yaml"
  if_exists = "overwrite"
  contents  = file("${get_terragrunt_dir()}/config/envoy.yaml")
}

generate "auth_lua" {
  path      = "generated-config/authentication_with_cug_header.lua"
  if_exists = "overwrite"
  contents  = file("${get_terragrunt_dir()}/config/authentication_with_cug_header.lua")
}

generate "no_auth_lua" {
  path      = "generated-config/no-auth.lua"
  if_exists = "overwrite"
  contents  = file("${get_terragrunt_dir()}/config/no-auth.lua")
}

inputs = {

  environment  = include.root.locals.environment.short
  region       = include.root.locals.region
  project_name = include.root.locals.project_name

  vpc_id = dependency.vpc.outputs.vpc_id

  proxy_subnet_ids = dependency.vpc.outputs.incoming_envoy_subnet_ids
  lb_subnet_ids    = dependency.vpc.outputs.external_incoming_subnet_ids

  # =========================================================================
  # Deployments (new — replaces single ASG with weighted multi-version)
  # =========================================================================
  deployments = {
    stable = {
      weight                  = 100
      launch_template_version = "$Latest"
    }
  }

  envoy_traffic_port = try(dependency.acm.outputs.certificate_statuses["envoy-alb"], "") == "ISSUED" ? 443 : 80

  # =========================================================================
  # Launch Template Configuration (was flat vars, now nested object)
  # =========================================================================
  launch_template = {
    create = true

    ami_id        = values.ami_id
    instance_type = "t3.medium"

    ebs_optimized           = false
    ebs_encrypted           = false
    enable_ebs_block_device = false
    root_volume_size        = 20
    root_volume_type        = "gp3"

    imds_http_tokens                 = "required"
    imds_http_endpoint               = "enabled"
    imds_http_put_response_hop_limit = 10
    imds_instance_metadata_tags      = "enabled"

    enable_detailed_monitoring = true

    # Versioning
    update_default_version = true
    default_version        = null
  }

  # =========================================================================
  # ASG Configuration
  # =========================================================================
  min_size         = 1
  max_size         = 10
  desired_capacity = 1

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

  # =========================================================================
  # S3 Buckets
  # =========================================================================
  create_logs_bucket   = true
  create_config_bucket = true

  # =========================================================================
  # Envoy Configuration
  # =========================================================================
  # Wazuh enrollment, sudo users and the TLS CN base domain are
  # environment-specific; supplied via stack values.
  custom_userdata = replace(replace(replace(replace(replace(replace(replace(
    file("${get_terragrunt_dir()}/templates/userdata.sh"),
    "{{update-wazuh}}", try(values.wazuh_manager_addr, "") != "" ? "Enable" : "Disable"),
    "{{wazuh-manager-addr}}", try(values.wazuh_manager_addr, "NA")),
    "{{wazuh-worker-addr}}", try(values.wazuh_worker_addr, "NA")),
    "{{wazuh-group}}", try(values.wazuh_group, "NA")),
    "{{wazuh-tag}}", try(values.wazuh_tag, "NA")),
    "{{sudo-user-list}}", try(values.sudo_user_list, "ubuntu")),
  "{{cn-base-domain}}", try(values.cn_base_domain, values.base_domain, "example.com"))

  envoy_config_template = file("${get_terragrunt_dir()}/config/envoy.yaml")

  upload_config_to_s3 = true

  # Rendered by the generate blocks above (relative to the terraform working dir).
  config_files_source_path = "generated-config"

  # hyperswitch_cloudfront_dns = "dXXXXXXXXXXXXX.cloudfront.net"
  internal_loadbalancer_dns = "istio.hyperswitch.internal"

  virtual_hosts_domains = flatten(values(values.virtual_hosts_domains))

  # =========================================================================
  # Load Balancer Configuration
  # =========================================================================
  create_lb           = true
  create_target_group = true
  lb_internal         = try(values.lb_internal, true)

  existing_lb_security_group_id = null

  enable_https_listener = try(dependency.acm.outputs.certificate_statuses["envoy-alb"], "") == "ISSUED"

  ssl_certificate_arn         = try(dependency.acm.outputs.certificate_statuses["envoy-alb"], "") == "ISSUED" ? dependency.acm.outputs.certificate_arns["envoy-alb"] : null
  additional_certificate_arns = []

  enable_http_to_https_redirect = try(dependency.acm.outputs.certificate_statuses["envoy-alb"], "") == "ISSUED"

  enable_waf = false

  target_group_protocol             = try(dependency.acm.outputs.certificate_statuses["envoy-alb"], "") == "ISSUED" ? "HTTPS" : "HTTP"
  target_group_deregistration_delay = 30

  health_check = {
    enabled             = true
    port                = try(dependency.acm.outputs.certificate_statuses["envoy-alb"], "") == "ISSUED" ? 443 : 80
    path                = "/ping"
    protocol            = try(dependency.acm.outputs.certificate_statuses["envoy-alb"], "") == "ISSUED" ? "HTTPS" : "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # =========================================================================
  # Spot Instance Configuration
  # =========================================================================
  enable_spot_instances = false

  spot_instance_percentage  = 50
  on_demand_base_capacity   = 1
  spot_allocation_strategy  = "capacity-optimized"
  enable_capacity_rebalance = false

  # =========================================================================
  # ASG Advanced Configuration
  # =========================================================================
  termination_policies = ["OldestLaunchTemplate", "OldestInstance", "Default"]

  max_instance_lifetime = 0

  generate_ssh_key = true

  create_iam_role = true

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
