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
  envoy_listener_port = var.envoy_listener_port
  envoy_admin_port    = var.envoy_admin_port
  ami_id              = var.ami_id
  instance_type       = var.instance_type

  # Port Configuration (Environment-specific)
  alb_http_listener_port  = var.alb_http_listener_port
  alb_https_listener_port = var.alb_https_listener_port
  envoy_traffic_port      = var.envoy_traffic_port
  envoy_health_check_port = var.envoy_health_check_port
  envoy_upstream_port     = var.envoy_upstream_port

  # SSH Key Configuration
  generate_ssh_key = var.generate_ssh_key
  key_name         = var.key_name  # Only used if generate_ssh_key=false

  # Userdata with templating ({{bucket-name}} and {{config_bucket}} will be replaced)
  custom_userdata = file("${path.module}/templates/userdata.sh")

  # Envoy config template ({{hyperswitch_cloudfront_dns}}, {{internal_loadbalancer_dns}}, {{eks_cluster_name}} replaced)
  envoy_config_template = file("${path.module}/config/envoy.yaml")

  # Template variables for envoy.yaml
  hyperswitch_cloudfront_dns = var.hyperswitch_cloudfront_dns
  internal_loadbalancer_dns  = var.internal_loadbalancer_dns

  # S3 Config Upload (optional)
  upload_config_to_s3      = var.upload_config_to_s3
  config_files_source_path = "${path.module}/config"
  config_bucket_name       = var.config_bucket_name
  config_bucket_arn        = var.config_bucket_arn

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

  # Instance Refresh (automatic rolling updates when config changes)
  enable_instance_refresh = var.enable_instance_refresh

  # Monitoring
  enable_detailed_monitoring = var.enable_detailed_monitoring
  root_volume_size           = var.root_volume_size
  root_volume_type           = var.root_volume_type

  tags = var.common_tags
}
