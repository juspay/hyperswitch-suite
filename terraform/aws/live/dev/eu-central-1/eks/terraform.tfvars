# =============================================================================
# EKS Cluster - Variable Values
# =============================================================================
# This configuration creates AWS infrastructure for EKS:
# - EKS cluster
# - IAM roles (cluster, IRSA for autoscaler, EBS CSI)
# - Node groups, launch templates
#
# Kubernetes resources (RBAC, storage classes, deployments) are created by
# the eks-03-k8s-resources module which depends on this one.
#
# NOTE: JSON policies (assume role policies, custom policies) are defined
# in main.tf locals because jsonencode() cannot be used in tfvars files.
# =============================================================================

# =============================================================================
# CORE CONFIGURATION
# =============================================================================

project_name         = "hyperswitch"
environment          = "dev"
region               = "eu-central-1"
cluster_version      = "1.35"
cluster_name_version = "01"

tags = {
  Environment = "dev"
  Project     = "hyperswitch"
  ManagedBy   = "terraform"
  Team        = "platform"
}

# =============================================================================
# NETWORKING
# =============================================================================

vpc_id     = "vpc-XXXXXXXXXXXXXXXXX"
subnet_ids = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXXXX"]

# Cluster endpoint access
cluster_endpoint_public_access  = true
cluster_endpoint_private_access = true

# CIDR blocks allowed to access public endpoint
cluster_endpoint_public_access_cidrs = [
  "X.X.X.X/32", # Office IP 1
  "X.X.X.X/32", # Office IP 2
  "X.X.X.X/32", # VPN IP
]

# VPN CIDR blocks for private access
vpn_cidr_blocks = [
  "X.X.X.X/32", # Office IP 1
  "X.X.X.X/32", # Office IP 2
  "X.X.X.X/32",
]

# =============================================================================
# CLUSTER ACCESS
# =============================================================================

cluster_access_entries = {
  admin_sso_role = {
    principal_arn = "arn:aws:iam::XXXXXXXXXXXX:role/aws-reserved/sso.amazonaws.com/ap-south-1/AWSReservedSSO_AWSAdministratorAccess_XXXXXXXXXXXXXXXX"
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

kms_key_administrators = [
  "arn:aws:iam::XXXXXXXXXXXX:role/aws-reserved/sso.amazonaws.com/ap-south-1/AWSReservedSSO_AWSAdministratorAccess_XXXXXXXXXXXXXXXX"
]

# =============================================================================
# CLUSTER IAM ROLE CONFIGURATION
# All policies defined explicitly in live layer - no hidden defaults
# NOTE: Assume role policy is defined in main.tf locals
# =============================================================================

create_cluster_iam_role = true

# Cluster IAM role policies
cluster_iam_role_policies = {
  AmazonEKSClusterPolicy = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Custom policy for cluster IAM role (optional - set to null to skip)
cluster_custom_policy_json = null

# =============================================================================
# NODE GROUP IAM ROLE CONFIGURATION
# All policies defined explicitly in live layer - no hidden defaults
# NOTE: Assume role policy and custom policy are defined in main.tf locals
# =============================================================================

create_node_group_iam_role = true

# Node group IAM role policies
node_group_iam_role_policies = {
  AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  AWSXrayFullAccess                  = "arn:aws:iam::aws:policy/AWSXrayFullAccess"
  CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# =============================================================================
# CROSS-ACCOUNT ROLE CONFIGURATION
# For ArgoCD, Atlantis, CI/CD from management cluster
# NOTE: Assume role policy and policy JSON are defined in main.tf locals
# =============================================================================

create_cross_account_role = true

# =============================================================================
# LAUNCH TEMPLATE CONFIGURATION
# =============================================================================

default_ami_id = "ami-0d763d29517d87c99"

# =============================================================================
# SSH KEY CONFIGURATION
# =============================================================================

create_ssh_key = true
ssh_key_name   = null
ssh_public_key = null

# =============================================================================
# DEFAULT BLOCK DEVICE CONFIGURATION
# =============================================================================

default_block_device_mappings = [
  {
    device_name           = "/dev/xvda"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }
]

# =============================================================================
# DEFAULT METADATA OPTIONS (IMDS)
# =============================================================================

default_metadata_options = {
  http_endpoint               = "enabled"
  http_tokens                 = "required"
  http_put_response_hop_limit = 2
  instance_metadata_tags      = "enabled"
}

# =============================================================================
# NODE GROUPS CONFIGURATION
# =============================================================================

node_groups = {
  system_nodes = {
    capacity_type  = "SPOT"
    instance_types = ["t3.medium"]
    subnet_ids     = ["subnet-XXXXXXXXXXXXXXXXX"]

    desired_size = 1
    min_size     = 0
    max_size     = 1

    max_unavailable_percentage = 33

    labels = {
      "node-type" = "system"
    }

    tags = {
      Workload = "system"
    }
  }
}

# =============================================================================
# EKS ADDONS CONFIGURATION
# =============================================================================

eks_addons = {
  "vpc-cni" = {
    addon_version = "v1.21.1-eksbuild.3"
  }
  "kube-proxy" = {
    addon_version = "v1.35.0-eksbuild.2"
  }
  "coredns" = {
    addon_version = "v1.13.2-eksbuild.1"
  }
  "aws-ebs-csi-driver" = {
    addon_version        = "v1.55.0-eksbuild.1"
    service_account_role = "ebs_csi"
  }
  "snapshot-controller" = {
    addon_version = "v8.3.0-eksbuild.1"
  }
  "metrics-server" = {
    addon_version = "v0.8.0-eksbuild.6"
  }
}
