provider "aws" {
  region = var.region
}

# Envoy Proxy Module
module "envoy_proxy" {
  source = "../../../../modules/composition/envoy-proxy"

  environment  = var.environment
  project_name = var.project_name

  # Network configuration
  vpc_id           = var.vpc_id
  proxy_subnet_ids = var.proxy_subnet_ids
  lb_subnet_ids    = var.lb_subnet_ids
  # Note: eks_security_group_id not needed - Envoy receives traffic from ALB, not from EKS

  # Envoy configuration
  ami_id        = var.ami_id
  instance_type = var.instance_type

  # Launch Template Configuration
  use_existing_launch_template      = var.use_existing_launch_template
  existing_launch_template_id       = var.existing_launch_template_id
  existing_launch_template_version  = var.existing_launch_template_version

  # Launch Template Advanced Configuration
  ebs_optimized                     = var.ebs_optimized
  ebs_encrypted                     = var.ebs_encrypted
  enable_ebs_block_device           = var.enable_ebs_block_device
  root_volume_size                  = var.root_volume_size
  root_volume_type                  = var.root_volume_type
  imds_http_tokens                  = var.imds_http_tokens
  imds_http_endpoint                = var.imds_http_endpoint
  imds_http_put_response_hop_limit  = var.imds_http_put_response_hop_limit
  imds_instance_metadata_tags       = var.imds_instance_metadata_tags

  # Port Configuration (Environment-specific)
  alb_http_listener_port  = var.alb_http_listener_port
  alb_https_listener_port = var.alb_https_listener_port
  envoy_traffic_port      = var.envoy_traffic_port   # ALB forwards traffic to this port on Envoy instances
  envoy_upstream_port     = var.envoy_upstream_port

  # SSH Key Configuration
  generate_ssh_key = var.generate_ssh_key
  key_name         = var.key_name  # Only used if generate_ssh_key=false

  # Userdata with templating ({{bucket-name}} and {{config_bucket}} will be replaced)
  custom_userdata = file("${path.module}/templates/userdata.sh")

  # Envoy config template ({{hyperswitch_cloudfront_dns}}, {{internal_loadbalancer_dns}}, {{eks_cluster_name}} replaced)
  envoy_config_template = file("${path.module}/config/${var.envoy_config_filename}")

  # Template variables for envoy.yaml
  hyperswitch_cloudfront_dns = var.hyperswitch_cloudfront_dns
  internal_loadbalancer_dns  = var.internal_loadbalancer_dns
  eks_cluster_name           = var.eks_cluster_name

  # S3 Logs Bucket - create or use existing
  create_logs_bucket = var.create_logs_bucket
  logs_bucket_name   = var.logs_bucket_name
  logs_bucket_arn    = var.logs_bucket_arn

  # S3 Config Bucket - create or use existing
  create_config_bucket     = var.create_config_bucket
  config_bucket_name       = var.config_bucket_name
  config_bucket_arn        = var.config_bucket_arn

  # S3 Config Upload (optional)
  upload_config_to_s3      = var.upload_config_to_s3
  config_files_source_path = "${path.module}/config"
  envoy_config_filename    = var.envoy_config_filename

  # ASG configuration
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Load Balancer - create new or use existing
  create_lb                     = var.create_lb
  create_target_group           = var.create_target_group
  existing_tg_arn               = var.existing_tg_arn
  existing_lb_arn               = var.existing_lb_arn
  existing_lb_security_group_id = var.existing_lb_security_group_id

  # SSL/TLS Configuration
  enable_https_listener         = var.enable_https_listener
  ssl_certificate_arn           = var.ssl_certificate_arn
  ssl_policy                    = var.ssl_policy
  enable_http_to_https_redirect = var.enable_http_to_https_redirect

  # Advanced Listener Rules
  listener_rules = var.listener_rules

  # WAF Configuration
  enable_waf      = var.enable_waf
  waf_web_acl_arn = var.waf_web_acl_arn

  # Target Group Configuration
  target_group_protocol             = var.target_group_protocol
  target_group_deregistration_delay = var.target_group_deregistration_delay

  # Health Check Configuration
  health_check = var.health_check

  # S3 VPC Endpoint
  s3_vpc_endpoint_prefix_list_id = var.s3_vpc_endpoint_prefix_list_id

  # Spot Instances Configuration
  enable_spot_instances     = var.enable_spot_instances
  spot_instance_percentage  = var.spot_instance_percentage
  on_demand_base_capacity   = var.on_demand_base_capacity
  spot_allocation_strategy  = var.spot_allocation_strategy
  enable_capacity_rebalance = var.enable_capacity_rebalance

  # ASG Advanced Configuration
  termination_policies  = var.termination_policies
  max_instance_lifetime = var.max_instance_lifetime

  # IAM Role Configuration
  create_iam_role                    = var.create_iam_role
  existing_iam_role_name             = var.existing_iam_role_name
  create_instance_profile            = var.create_instance_profile
  existing_iam_instance_profile_name = var.existing_iam_instance_profile_name

  # Auto Scaling Policies
  enable_autoscaling = var.enable_autoscaling
  scaling_policies   = var.scaling_policies

  # Monitoring
  enable_detailed_monitoring = var.enable_detailed_monitoring

  tags = var.common_tags
}
