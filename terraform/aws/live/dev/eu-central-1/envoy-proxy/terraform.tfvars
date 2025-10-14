# Development Environment - EU Central 1 - Envoy Proxy

environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# Network Configuration
# TODO: Replace with your actual VPC and subnet IDs
vpc_id = "vpc-xxxxxxxxx"
proxy_subnet_ids = [
  "subnet-xxxxxxxxx",
  "subnet-yyyyyyyyy"
]
lb_subnet_ids = [
  "subnet-zzzzzzzzz",
  "subnet-aaaaaaaaa"
]

# EKS Configuration
# TODO: Replace with your actual EKS security group ID
eks_security_group_id = "sg-xxxxxxxxx"

# Envoy Configuration
envoy_admin_port    = 9901
envoy_listener_port = 10000

# EC2 Configuration
# TODO: Replace with your actual AMI ID
ami_id        = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 in eu-central-1
instance_type = "t3.small"
key_name      = null

# Auto Scaling Configuration
min_size         = 1
max_size         = 2
desired_capacity = 1

# S3 Configuration
# TODO: Create this bucket first
config_bucket_name = "hyperswitch-dev-proxy-config-eu-central-1"
config_bucket_arn  = "arn:aws:s3:::hyperswitch-dev-proxy-config-eu-central-1"

# Monitoring
enable_detailed_monitoring = false

# Storage
root_volume_size = 20
root_volume_type = "gp3"

# Tags
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
