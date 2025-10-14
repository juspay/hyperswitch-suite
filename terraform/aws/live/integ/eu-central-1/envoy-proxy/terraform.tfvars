# Integration Environment - EU Central 1 - Envoy Proxy

environment  = "integ"
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
ami_id        = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
instance_type = "t3.medium"
key_name      = null

# Auto Scaling Configuration
min_size         = 1
max_size         = 3
desired_capacity = 2

# S3 Configuration
# TODO: Create this bucket first
config_bucket_name = "hyperswitch-integ-proxy-config-eu-central-1"
config_bucket_arn  = "arn:aws:s3:::hyperswitch-integ-proxy-config-eu-central-1"

# Monitoring
enable_detailed_monitoring = true

# Storage
root_volume_size = 30
root_volume_type = "gp3"

# Tags
common_tags = {
  Environment = "integration"
  Project     = "hyperswitch"
  ManagedBy   = "terraform"
  Team        = "platform"
  CostCenter  = "engineering"
  Region      = "eu-central-1"
}
