# Basic EKS Configuration
project_name    = "hyperswitch"
environment     = "dev"
cluster_version = "1.34"

# VPN Access Configuration
# VPN IP addresses for accessing EKS cluster
# vpn_cidr_blocks = ["1.2.3.128/32", "1.2.7.226/32", "3.7.1.245/32"]
# vpn_cidr_blocks = []

# Deployment Management
# Set to false if using ArgoCD from another cluster to manage deployments
enable_helm_deployments = false

# Networking - REPLACE WITH YOUR ACTUAL VALUES
vpc_id = "vpc-xxxx"  # Replace with your VPC ID
subnet_ids = [            # Replace with your subnet IDs
  "subnet-xxxx",     # Subnet 1
  "subnet-xxxx",     # Subnet 2
  "subnet-xxxx"
]

argocd_assume_role_principal_arn = "arn:aws:iam::yyyyyyyy:role/argocd-management-role"
# Basic Node Group
node_groups = {
  general = {
    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 3
    desired_size   = 2

    # Use AL2023 (required for K8s 1.34, AL2 only supports up to 1.32)
    ami_type = "AL2023_x86_64_STANDARD"

    # Explicitly invoke nodeadm via pre-bootstrap user data to work around cloud-init issue
    cloudinit_pre_nodeadm = [
      {
        content_type = "text/x-shellscript"
        content      = <<-EOT
          #!/bin/bash
          set -ex
          # Force nodeadm to run the bootstrap configuration
          /usr/bin/nodeadm init --skip nodeadm://cluster-dns-config || true
        EOT
      }
    ]

    # Tags for Cluster Autoscaler discovery
    tags = {
      "k8s.io/cluster-autoscaler/enabled"                = "true"
      "k8s.io/cluster-autoscaler/dev-hyperswitch-cluster" = "owned"
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
}

# EKS Cluster Access Entries
# Grant IAM principals access to the cluster
cluster_access_entries = {
  admin_sso_role = {
    # SSO role ARN with correct path including region for accessing locally
    principal_arn = "arn:aws:iam::yyyyyyyy:role/aws-reserved/sso.amazonaws.com/ap-south-1/AWSReservedSSO_AWSAdministratorAccess_ebf3e1964512148f"

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
