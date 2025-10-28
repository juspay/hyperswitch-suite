provider "aws" {
  region = var.region
}

# Envoy Proxy Module
module "envoy_proxy" {
  source = "../../../../../modules/composition/envoy-proxy"

  environment  = var.environment
  project_name = var.project_name

  vpc_id           = var.vpc_id
  proxy_subnet_ids = var.proxy_subnet_ids
  lb_subnet_ids    = var.lb_subnet_ids

  eks_security_group_id = var.eks_security_group_id

  envoy_admin_port    = var.envoy_admin_port
  envoy_listener_port = var.envoy_listener_port
  ami_id              = var.ami_id
  instance_type       = var.instance_type
  key_name            = var.key_name

  # Port Configuration (Environment-specific)
  alb_http_listener_port  = var.alb_http_listener_port
  alb_https_listener_port = var.alb_https_listener_port
  envoy_traffic_port      = var.envoy_traffic_port
  envoy_health_check_port = var.envoy_health_check_port
  envoy_upstream_port     = var.envoy_upstream_port

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  config_bucket_name = var.config_bucket_name
  config_bucket_arn  = var.config_bucket_arn

  enable_detailed_monitoring = var.enable_detailed_monitoring
  root_volume_size           = var.root_volume_size
  root_volume_type           = var.root_volume_type

  tags = var.common_tags
}
