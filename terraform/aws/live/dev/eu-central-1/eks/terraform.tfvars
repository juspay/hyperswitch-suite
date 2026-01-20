# Basic EKS Configuration
project_name         = "hyperswitch"
environment          = "dev"
cluster_version      = "1.34"
region               = "eu-central-1"
cluster_name_version = "03"

# EKS Cluster Endpoint Access Configuration
# Control access to the EKS API server endpoint
cluster_endpoint_public_access  = true
cluster_endpoint_private_access = true

# Public API Server Endpoint Access Allowlist
# Only these CIDR blocks can access the public EKS API endpoint
cluster_endpoint_public_access_cidrs = [
  "XX.XXX.XX.XXX/32",   # Access point 1
  "XX.XXX.XX.XXX/32",   # Access point 2
  "XX.XXX.XX.XXX/32",   # Access point 3
  "XX.XXX.XX.XXX/32",   # Access point 4
  "XX.XXX.XX.XXX/32",   # Access point 5
  "XX.XXX.XX.XXX/32",   # Access point 6
  "XX.XXX.XX.XXX/32",   # Access point 7
  "XX.XXX.XX.XXX/32",   # Access point 8
  "XX.XXX.XX.XXX/32"    # Access point 9
]

# VPN Access Configuration
# VPN IP addresses for accessing EKS cluster
vpn_cidr_blocks = ["XX.XXX.XX.XXX/32","XX.XXX.XX.XXX/32","XX.XXX.XX.XXX/32"]

# Deployment Management
# Set to false if using ArgoCD from another cluster to manage deployments
enable_helm_deployments = false

enable_cluster_autoscaler = false

# Networking - REPLACE WITH YOUR ACTUAL VALUES
vpc_id = "vpc-XXXXXXXXXXXXXXXXX"  # Replace with your VPC ID
subnet_ids = [            # Replace with your subnet IDs
  "subnet-XXXXXXXXXXXXXXXXX",     # Subnet 1
  "subnet-XXXXXXXXXXXXXXXXX",     # Subnet 2
]

argocd_assume_role_principal_arn = "arn:aws:iam::XXXXXXXXXXXX:role/AmazonEKSAutoClusterRole"

node_groups = {
  node_group_1 = {
    capacity_type = "ON_DEMAND"
    min_size      = 1 
    max_size      = 2
    desired_size  = 1 
    instance_types = ["t3.small"]
    subnet_ids   = [  "subnet-XXXXXXXXXXXXXXXXX","subnet-XXXXXXXXXXXXXXXXX" ]  

    labels = {
      "node-type" = "node-group-1"
    }
    tags = {
      stack = "hyperswitch"
    }
  }

# node group two with custom security group
  node_group_2 = {
    capacity_type = "ON_DEMAND"
    min_size      = 1
    max_size      = 2
    desired_size  = 1
    instance_types = ["t3.small"]
    subnet_ids   = [  "subnet-XXXXXXXXXXXXXXXXX","subnet-XXXXXXXXXXXXXXXXX" ] 
    custom_launch_template_config = {
      additional_security_group_ids = ["sg-XXXXXXXXXXXXXXXXX"]  # Additional SGs
    }
    labels = {
      "node-type" = "node-group-2"
    }
    tags = {
      stack = "hyperswitch"
    }
  }
}

# EKS Addon Versions
# Pinned addon versions for Kubernetes 1.34
eks_addon_versions = {
  vpc-cni             = "v1.21.1-eksbuild.1"
  coredns             = "v1.12.4-eksbuild.1"
  kube-proxy          = "v1.34.1-eksbuild.2"
  aws-ebs-csi-driver  = "v1.54.0-eksbuild.1"
  snapshot-controller = "v8.3.0-eksbuild.1"
  metrics-server      = "v0.8.0-eksbuild.6"
}

# EKS Cluster Access Entries
# Grant IAM principals access to the cluster
cluster_access_entries = {
  admin_sso_role = {
    # SSO role ARN with correct path including region for accessing locally
    principal_arn = "arn:aws:iam::XXXXXXXXXXXX:role/aws-reserved/sso.amazonaws.com/REGION/AWSReservedSSO_AWSAdministratorAccess_XXXXXXXXXXXXXXXX"

    policy_associations = {
      admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type = "cluster"
        }
      }
    }
  }
}

# Tags
tags = {
  Environment = "dev"
  Project     = "hyperswitch"
  ManagedBy   = "terraform"
}
