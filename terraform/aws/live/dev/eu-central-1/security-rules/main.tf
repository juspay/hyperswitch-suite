# ============================================================================
# Security Rules Deployment - Dev Environment
# ============================================================================
# This configuration manages cross-module security group rules:
#   - Fetches security group IDs from other modules via terraform_remote_state
#   - Defines rules organized by component (locker, squid, envoy, jump-host)
#   - Merges rules into consolidated ingress/egress lists
#   - Passes merged lists to the security-rules module
#
# Dependencies: Must be applied AFTER infrastructure modules (locker, jump-host, etc.)
# ============================================================================

provider "aws" {
  region = "eu-central-1"
}

# =========================================================================
# DATA SOURCES - FETCH SECURITY GROUP IDs FROM OTHER MODULES
# =========================================================================

# Locker module state
data "terraform_remote_state" "locker" {
  backend = "s3"
  config = {
    bucket = "hyperswitch-dev-terraform-state"
    key    = "dev/eu-central-1/locker/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "squid_proxy" {
  backend = "s3"
  config = {
    bucket = "hyperswitch-dev-terraform-state"
    key    = "dev/eu-central-1/squid-proxy/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "envoy_proxy" {
  backend = "s3"
  config = {
    bucket = "hyperswitch-dev-terraform-state"
    key    = "dev/eu-central-1/envoy-proxy/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "jump_host" {
  backend = "s3"
  config = {
    bucket = "hyperswitch-dev-terraform-state"
    key    = "dev/eu-central-1/jump-host/terraform.tfstate"
    region = "eu-central-1"
  }
}

# EKS module state (uncomment when ready)
# data "terraform_remote_state" "eks" {
#   backend = "s3"
#   config = {
#     bucket = "hyperswitch-dev-terraform-state"
#     key    = "dev/eu-central-1/eks/terraform.tfstate"
#     region = "eu-central-1"
#   }
# }

# =========================================================================
# LOCAL VARIABLES - ORGANIZE RULES BY COMPONENT
# =========================================================================
locals {
  # =========================================================================
  # LOCKER COMPONENT RULES
  # =========================================================================
  locker_ingress_rules = [
    # SSH access from jump host
    {
      description = "SSH access from jump host"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      sg_id       = ["sg-xxxxxxxxxxxxxxxxx"] # Replace with jump host security group ID
    },
    # Example: Vector metrics endpoint from EKS monitoring (uncomment if needed)
    # {
    #   description = "Vector metrics scraping"
    #   from_port   = 9273
    #   to_port     = 9273
    #   protocol    = "tcp"
    #   sg_id       = ["sg-xxxxxxxxxxxxxxxxx"]  # Replace with monitoring security group ID
    # },
  ]

  locker_egress_rules = [
    # HTTPS for ECR, S3, AWS services
    {
      description = "HTTPS access for ECR, S3, and AWS services"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr        = ["0.0.0.0/0"]
    },
    # HTTP for package downloads
    {
      description = "HTTP access for package downloads"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr        = ["0.0.0.0/0"]
    },
    # PostgreSQL access to RDS
    {
      description = "PostgreSQL access to RDS database"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      sg_id       = ["sg-xxxxxxxxxxxxxxxxx"] # Replace with RDS security group ID
    },
    # Example: Redis access (uncomment if needed)
    # {
    #   description = "Redis access"
    #   from_port   = 6379
    #   to_port     = 6379
    #   protocol    = "tcp"
    #   sg_id       = ["sg-xxxxxxxxxxxxxxxxx"]  # Replace with Redis security group ID
    # },
  ]

  # =========================================================================
  # NLB (LOCKER) COMPONENT RULES
  # =========================================================================
  nlb_ingress_rules = [
    # HTTPS access from jump host
    {
      description = "HTTPS access from jump host"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      sg_id       = ["sg-xxxxxxxxxxxxxxxxx"] # Replace with jump host security group ID
    },
    # Example: HTTPS from specific CIDR (uncomment if needed)
    # {
    #   description = "HTTPS from internal network"
    #   from_port   = 443
    #   to_port     = 443
    #   protocol    = "tcp"
    #   cidr        = ["10.0.0.0/16"]  # Replace with your CIDR
    # },
  ]

  nlb_egress_rules = [
    # Add additional egress rules here if needed
    # Example: All outbound traffic (uncomment if needed)
    # {
    #   description = "Allow all outbound traffic"
    #   from_port   = 0
    #   to_port     = 0
    #   protocol    = "-1"
    #   cidr        = ["0.0.0.0/0"]
    # },
  ]

  # =========================================================================
  # SQUID PROXY COMPONENT RULES
  # =========================================================================
  squid_ingress_rules = [
    {
      description = "Allow traffic from EKS worker subnets"
      from_port   = 3128
      to_port     = 3128
      protocol    = "tcp"
      cidr        = ["10.X.X.0/21", "10.X.X.0/24"] # Replace with your EKS worker subnet CIDRs
    },
    # Example 2: Allow SSH from jumpbox security group
    # {
    #   description = "Allow SSH access from external jumpbox"
    #   from_port   = 22
    #   to_port     = 22
    #   protocol    = "tcp"
    #   sg_id       = ["sg-XXXXXXXXXXXXX"]
    # },
    # Example 3: Allow Prometheus metrics scraping from Prometheus security group
    # {
    #   description = "Allow Prometheus metrics scraping"
    #   from_port   = 9273
    #   to_port     = 9273
    #   protocol    = "tcp"
    #   sg_id       = ["sg-XXXXXXXXXXXXX"]
    # },
  ]

  squid_egress_rules = [
    # Allow HTTPS access to the internet
    {
      description = "Allow HTTPS to internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr        = ["0.0.0.0/0"]
    },
    # Example 1: Allow outbound to Wazuh master (CIDR blocks)
    # {
    #   description = "Wazuh master"
    #   from_port   = 1515
    #   to_port     = 1515
    #   protocol    = "tcp"
    #   cidr        = ["10.41.16.0/20"]
    # },
    # Example 2: Allow outbound to ClamAV (Security Group ID)
    # {
    #   description = "ClamAV antivirus service"
    #   from_port   = 3310
    #   to_port     = 3310
    #   protocol    = "tcp"
    #   sg_id       = ["sg-XXXXXXXXXXXXX"]
    # },
    # Example 3: Allow outbound to custom application on non-standard port
    # {
    #   description = "Custom API endpoint"
    #   from_port   = 8443
    #   to_port     = 8443
    #   protocol    = "tcp"
    #   cidr        = ["192.168.1.0/24"]
    # },
  ]

  # =========================================================================
  # ENVOY PROXY COMPONENT RULES
  # =========================================================================
  envoy_ingress_rules = [
    # Example: SSH access from jumpbox/bastion
    {
      description = "Allow SSH from jumpbox"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      sg_id       = ["sg-xxxxxxxxxxxxx"] # Replace with your jumpbox security group ID
    },
    # Example: Prometheus metrics scraping
    {
      description = "Allow Prometheus metrics scraping"
      from_port   = 9901
      to_port     = 9901
      protocol    = "tcp"
      sg_id       = ["sg-yyyyyyyyyyyyyyy"] # Replace with your monitoring SG ID
    },
  ]

  envoy_egress_rules = [
    # -------------------------------------------------------------------------
    # DNS Resolution (Required)
    # -------------------------------------------------------------------------
    {
      description = "Allow DNS UDP"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr        = ["0.0.0.0/0"]
    },
    {
      description = "Allow DNS TCP"
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr        = ["0.0.0.0/0"]
    },

    # -------------------------------------------------------------------------
    # S3 Access (Required for config/logs)
    # -------------------------------------------------------------------------
    # Option 1: Via VPC Endpoint (Recommended - uncomment and set prefix list ID)
    # {
    #   description     = "Allow HTTPS to S3 via VPC Gateway Endpoint"
    #   from_port       = 443
    #   to_port         = 443
    #   protocol        = "tcp"
    #   prefix_list_ids = ["pl-6xxxxxxx7"]  # S3 prefix list for eu-central-1
    # },

    # Option 2: Via Internet (Current - fallback)
    {
      description = "Allow HTTPS to S3"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr        = ["0.0.0.0/0"]
    },

    # -------------------------------------------------------------------------
    # Upstream Traffic (Application-Specific)
    # -------------------------------------------------------------------------
    # Traffic to Istio Internal LB / EKS
    {
      description = "Allow traffic to Istio Internal LB"
      from_port   = 80 # var.envoy_upstream_port - adjust as needed
      to_port     = 80
      protocol    = "tcp"
      cidr        = ["0.0.0.0/0"] # Will be restricted by destination ALB SG
    },

    # HTTP to Internal ALB (EKS)
    {
      description = "Allow HTTP to Internal ALB (EKS)"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      sg_id       = ["sg-xxxxxxxxxxxxxxxxxx"] # k8s-elb (Internal ALB SG) - temp for testing
    },

    # -------------------------------------------------------------------------
    # Environment-Specific Services
    # -------------------------------------------------------------------------
    # Custom TCP 5000 to Beacon service
    {
      description = "Allow traffic to Beacon service"
      from_port   = 5000
      to_port     = 5000
      protocol    = "tcp"
      sg_id       = ["sg-xxxxxxxxxxxxxxxxx"] # beacon-sg - temp for testing
    },
  ]

  # =========================================================================
  # ENVOY LOAD BALANCER COMPONENT RULES
  # =========================================================================
  envoy_lb_ingress_rules = [
    # Example: HTTP from anywhere (IPv4)
    {
      description = "Allow HTTP from anywhere (IPv4)"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr        = ["0.0.0.0/0"]
    },
    # Example: HTTPS from anywhere (IPv4)
    {
      description = "Allow HTTPS from anywhere (IPv4)"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr        = ["0.0.0.0/0"]
    },
    # Example: IPv6 support (optional - uncomment if needed)
    # {
    #   description = "Allow HTTP from anywhere (IPv6)"
    #   from_port   = 80
    #   to_port     = 80
    #   protocol    = "tcp"
    #   ipv6_cidr   = ["::/0"]
    # },
  ]

  envoy_lb_egress_rules = [
    # Example: Traffic to backend service
    {
      description = "Allow traffic to backend service"
      from_port   = 5000
      to_port     = 5000
      protocol    = "tcp"
      sg_id       = ["sg-xxxxxxxxxxxxx"] # Replace with your backend service SG ID
    },
    # Note: Traffic to Envoy ASG on envoy_traffic_port is automatically handled
    # by the composition layer (creates egress rule to ASG security group dynamically)
  ]

  # =========================================================================
  # JUMP HOST COMPONENT RULES
  # =========================================================================
  # ----------------------------------------------------------------------------
  # External Jump Host - Ingress Rules
  # ----------------------------------------------------------------------------
  # Allow access from VPN IPs or specific CIDR blocks
  # Example: CIDR-based ingress rule
  # ext_jump_host_ingress_rules = [
  #   {
  #     description = "VPN/Office IP - SSH/SSM access"
  #     from_port   = 22
  #     to_port     = 22
  #     protocol    = "tcp"
  #     cidr        = ["x.x.x.x/32"]  # Replace with your VPN/office IP
  #   }
  # ]

  ext_jump_host_ingress_rules = []

  ext_jump_host_egress_rules = [
    {
      description = "SSH to application servers"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      sg_id       = ["sg-xxxxxxxxxxxxxxxxx"] # Replace with target security group ID
    },
    {
      description = "Monitoring system access"
      from_port   = 1514
      to_port     = 1514
      protocol    = "tcp"
      cidr        = ["10.0.0.0/16"] # Replace with your VPC CIDR or monitoring subnet
    },
  ]

  int_jump_host_ingress_rules = []

  int_jump_host_egress_rules = [
    {
      description = "Database access (PostgreSQL/MySQL)"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      sg_id       = ["sg-xxxxxxxxxxxxxxxxx"] # Replace with database security group ID
    },
    {
      description = "S3 VPC endpoint access"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      prefix_list_ids = ["pl-xxxxxxxx"] # Replace with S3 prefix list for your region
    },
    {
      description = "HTTP/HTTPS to VPC CIDR on custom ports"
      from_port   = 1514
      to_port     = 1514
      protocol    = "tcp"
      cidr        = ["10.X.X.0/16"] # Replace with your VPC CIDR
    },
  ]

  # =========================================================================
  # CONSOLIDATED INGRESS RULES
  # =========================================================================
  # Merge all component ingress rules into a single list
  all_ingress_rules = concat(
    length(local.locker_ingress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.locker.outputs.locker_security_group_id
      rules = local.locker_ingress_rules
    }] : [],
    length(local.nlb_ingress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.locker.outputs.locker_nlb_security_group_id
      rules = local.nlb_ingress_rules
    }] : [],
    length(local.squid_ingress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.squid_proxy.outputs.squid_asg_security_group_id
      rules = local.squid_ingress_rules
    }] : [],
    length(local.envoy_ingress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.envoy_proxy.outputs.envoy_security_group_id
      rules = local.envoy_ingress_rules
    }] : [],
    length(local.envoy_lb_ingress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.envoy_proxy.outputs.envoy_lb_security_group_id
      rules = local.envoy_lb_ingress_rules
    }] : [],
    length(local.ext_jump_host_ingress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.jump_host.outputs.external_security_group_id
      rules = local.ext_jump_host_ingress_rules
    }] : [],
    length(local.int_jump_host_ingress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.jump_host.outputs.internal_security_group_id
      rules = local.int_jump_host_ingress_rules
    }] : []
  )

  # =========================================================================
  # CONSOLIDATED EGRESS RULES
  # =========================================================================
  # Merge all component egress rules into a single list
  all_egress_rules = concat(
    length(local.locker_egress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.locker.outputs.locker_security_group_id
      rules = local.locker_egress_rules
    }] : [],
    length(local.nlb_egress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.locker.outputs.locker_nlb_security_group_id
      rules = local.nlb_egress_rules
    }] : [],
    length(local.squid_egress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.squid_proxy.outputs.squid_asg_security_group_id
      rules = local.squid_egress_rules
    }] : [],
    length(local.envoy_egress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.envoy_proxy.outputs.envoy_security_group_id
      rules = local.envoy_egress_rules
    }] : [],
    length(local.envoy_lb_egress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.envoy_proxy.outputs.envoy_lb_security_group_id
      rules = local.envoy_lb_egress_rules
    }] : [],
    length(local.ext_jump_host_egress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.jump_host.outputs.external_security_group_id
      rules = local.ext_jump_host_egress_rules
    }] : [],
    length(local.int_jump_host_egress_rules) > 0 ? [{
      sg_id = data.terraform_remote_state.jump_host.outputs.internal_security_group_id
      rules = local.int_jump_host_egress_rules
    }] : []
  )
}

# =========================================================================
# SECURITY RULES MODULE
# =========================================================================
module "security_rules" {
  source = "../../../../modules/composition/security-rules"

  # Pass consolidated ingress and egress rules
  ingress_rules = local.all_ingress_rules
  egress_rules  = local.all_egress_rules
}
