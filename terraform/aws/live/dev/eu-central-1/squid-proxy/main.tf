# Example: Using Existing Load Balancer
# Rename this to main.tf to use

provider "aws" {
  region = var.region
}

# Reference your existing load balancer
data "aws_lb" "existing" {
  name = var.existing_lb_name  # or use: arn = var.existing_lb_arn
}

# Reference existing listener on the load balancer
data "aws_lb_listener" "existing" {
  load_balancer_arn = data.aws_lb.existing.arn
  port              = var.squid_port  # or the port your listener is on
}

# Read your custom userdata script
locals {
  custom_userdata = file("${path.module}/userdata.sh")
}

# Squid Proxy Module - Using Existing LB
module "squid_proxy" {
  source = "../../../../modules/composition/squid-proxy"

  environment  = var.environment
  project_name = var.project_name

  # Network configuration
  vpc_id           = var.vpc_id
  proxy_subnet_ids = var.proxy_subnet_ids
  lb_subnet_ids    = var.lb_subnet_ids

  eks_security_group_id = var.eks_security_group_id

  # Squid configuration
  squid_port    = var.squid_port
  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  # ASG configuration
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # S3 configuration
  config_bucket_name = var.config_bucket_name
  config_bucket_arn  = var.config_bucket_arn

  # Monitoring
  enable_detailed_monitoring = var.enable_detailed_monitoring
  root_volume_size           = var.root_volume_size
  root_volume_type           = var.root_volume_type

  # ========================================
  # EXISTING LOAD BALANCER CONFIGURATION
  # ========================================
  create_nlb                = false  # Don't create new NLB
  existing_lb_arn           = data.aws_lb.existing.arn
  existing_lb_listener_arn  = data.aws_lb_listener.existing.arn

  # Create target group and attach to ASG
  # After terraform apply, manually update the existing NLB listener's
  # default action to forward to the created target group ARN (check outputs)

  tags = var.common_tags
}
