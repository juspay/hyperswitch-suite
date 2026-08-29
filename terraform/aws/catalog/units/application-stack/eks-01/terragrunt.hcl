# =============================================================================
# EKS Cluster - Terragrunt Configuration
# =============================================================================
# This configuration creates AWS infrastructure for EKS:
# - EKS cluster
# - IAM roles (cluster, IRSA for autoscaler, EBS CSI)
# - Node groups, launch templates
#
# Kubernetes resources (RBAC, storage classes, deployments) are created by
# the eks-03-k8s-resources module which depends on this one.
# =============================================================================

# -----------------------------------------------------------------------------
# Include Root Configuration
# -----------------------------------------------------------------------------
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# -----------------------------------------------------------------------------
# Dependencies
#
# Standalone (self-host) stacks provide the VPC directly via values
# (vpc_id, eks_control_plane_subnet_ids, eks_workers_subnet_ids) and do not
# run a management cluster: set no management values and the argocd/atlantis
# dependencies below stay disabled.
# -----------------------------------------------------------------------------
dependency "vpc" {
  enabled     = try(values.vpc_id, null) == null
  config_path = "../../vpc-network"

  mock_outputs = {
    eks_control_plane_subnet_ids = ["mock-eks_control_plane_subnet_ids"]
    eks_workers_subnet_ids       = ["mock-eks_workers_subnet_ids"]
    vpc_id                       = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "vpc-management" {
  enabled     = try(values.enable_management_integration, false) && try(values.nat_ips, null) == null
  config_path = try("../../../${values.management_region}/vpc-network", "unused-vpc-management")

  mock_outputs = {
    nat_gateway_public_ips = ["203.0.113.1/32"]
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "argocd" {
  enabled     = try(values.enable_management_integration, false)
  config_path = try("../../../${values.management_region}/management-stack/apps/argocd", "unused-argocd")

  mock_outputs = {
    role_arn = "arn:aws:iam::123456789012:role/mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "atlantis-primary" {
  enabled     = try(values.enable_management_integration, false)
  config_path = try("../../../${values.primary_region}/management-stack/apps/atlantis", "unused-atlantis-primary")

  mock_outputs = {
    role_arn = "arn:aws:iam::123456789012:role/mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "atlantis-management" {
  enabled     = try(values.enable_management_integration, false)
  config_path = try("../../../${values.management_region}/management-stack/apps/atlantis", "unused-atlantis-management")

  mock_outputs = {
    role_arn = "arn:aws:iam::123456789012:role/mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# -----------------------------------------------------------------------------
# Terragrunt Configuration
# -----------------------------------------------------------------------------
terraform {
  # TODO(release): cut an `eks-v0.1.6` module tag from the
  # `chore/add-node-os-support` branch and pin it here before tagging this unit.
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/eks?ref=chore/add-node-os-support"
}

# -----------------------------------------------------------------------------
# Inputs - All configurable options
# -----------------------------------------------------------------------------
inputs = {
  # ===========================================================================
  # CORE CONFIGURATION
  # ===========================================================================

  project_name         = include.root.locals.project_name
  environment          = include.root.locals.environment.short
  region               = include.root.locals.region
  cluster_version      = try(values.cluster_version, "1.35")
  cluster_name_version = "01"

  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    ManagedBy   = "terragrunt"
    Team        = "Infra"
  }

  # ===========================================================================
  # NETWORKING
  # ===========================================================================

  vpc_id     = try(values.vpc_id, null) != null ? values.vpc_id : dependency.vpc.outputs.vpc_id
  subnet_ids = try(values.eks_control_plane_subnet_ids, null) != null ? values.eks_control_plane_subnet_ids : dependency.vpc.outputs.eks_control_plane_subnet_ids

  # Cluster endpoint access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # CIDR blocks allowed to access public endpoint
  cluster_endpoint_public_access_cidrs = concat(
    try(values.ip_list.vpn_cidr_blocks, []),
    try(values.admin_access_cidrs, []),
    try(values.nat_ips, null) != null ? values.nat_ips : (
      try(values.enable_management_integration, false) ? [for ip in dependency.vpc-management.outputs.nat_gateway_public_ips : "${ip}/32"] : []
    )
  )

  # VPN CIDR blocks for private access
  vpn_cidr_blocks = concat(try(values.ip_list.vpn_cidr_blocks, []), try(values.admin_access_cidrs, []))

  # ===========================================================================
  # CLUSTER ACCESS
  # ===========================================================================

  cluster_access_entries = merge(
    {
      admin_sso_role = {
        principal_arn = values.admin_sso_role_arn
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    },
    try(values.view_sso_role_arn, null) != null ? {
      view_sso_role = {
        principal_arn = values.view_sso_role_arn
        policy_associations = {
          view = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {},
    try(values.enable_management_integration, false) ? {
      atlantis = {
        principal_arn = dependency.atlantis-primary.outputs.role_arn
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {},
    try(values.extra_admin_view_role_arn, null) != null ? {
      inframcp_role = {
        principal_arn = values.extra_admin_view_role_arn
        policy_associations = {
          admin_view = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {}
  )

  kms_key_administrators = [
    values.admin_sso_role_arn
  ]

  # ===========================================================================
  # CLUSTER IAM ROLE CONFIGURATION
  # All policies defined explicitly in live layer - no hidden defaults
  # ===========================================================================

  create_cluster_iam_role = true

  # Cluster IAM role assume role policy
  # Define who can assume this role (EKS service + optional management-cluster ArgoCD)
  cluster_iam_role_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Principal = {
            Service = "eks.amazonaws.com"
          }
          Action = "sts:AssumeRole"
        }
      ],
      # Allow ArgoCD from the management cluster to assume this role
      try(values.enable_management_integration, false) ? [
        {
          Effect = "Allow"
          Principal = {
            AWS = dependency.argocd.outputs.role_arn
          }
          Action = "sts:AssumeRole"
        }
      ] : []
    )
  })

  # Cluster IAM role policies
  cluster_iam_role_policies = {
    AmazonEKSClusterPolicy = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  }

  # Custom policy for cluster IAM role (optional - set to null to skip)
  cluster_custom_policy_json = null

  # ===========================================================================
  # NODE GROUP IAM ROLE CONFIGURATION
  # All policies defined explicitly in live layer - no hidden defaults
  # ===========================================================================

  create_node_group_iam_role = true

  # Node group IAM role assume role policy
  node_group_iam_role_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # Node group IAM role policies
  node_group_iam_role_policies = {
    AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AWSXrayFullAccess                  = "arn:aws:iam::aws:policy/AWSXrayFullAccess"
    CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  # Node group custom policy (observability + optional ECR pull-through cache +
  # optional read access to the terraform state bucket for in-cluster tooling)
  node_group_custom_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "CloudWatchLogsObservability"
          Effect = "Allow"
          Action = [
            "cloudwatch:DescribeAlarmsForMetric",
            "cloudwatch:DescribeAlarmHistory",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:ListMetrics",
            "cloudwatch:GetMetricData",
            "cloudwatch:GetInsightRuleReport",
            "logs:DescribeLogGroups",
            "logs:GetLogGroupFields",
            "logs:StartQuery",
            "logs:StopQuery",
            "logs:GetQueryResults",
            "logs:GetLogEvents",
            "ec2:DescribeTags",
            "ec2:DescribeInstances",
            "ec2:DescribeRegions",
            "tag:GetResources"
          ]
          Resource = "*"
        }
      ],
      try(values.ecr_pull_through_account, null) != null ? [
        {
          Sid    = "ECRPullThroughCacheCentral"
          Effect = "Allow"
          Action = [
            "ecr:BatchImportUpstreamImage",
            "ecr:CreateRepository"
          ]
          Resource = "arn:aws:ecr:*:${values.ecr_pull_through_account}:repository/*"
        }
      ] : [],
      try(values.state_bucket_read_access, false) ? [
        {
          Sid    = "TerraformStateRead"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Resource = [
            "arn:aws:s3:::${values.state_bucket}",
            "arn:aws:s3:::${values.state_bucket}/*"
          ]
        }
      ] : []
    )
  })

  # ===========================================================================
  # CROSS-ACCOUNT ROLE CONFIGURATION
  # For ArgoCD, Atlantis, CI/CD from management cluster
  # All policies defined explicitly in live layer - no hidden defaults
  # ===========================================================================

  create_cross_account_role = try(values.enable_management_integration, false)

  # Cross-account role assume role policy
  # Define who can assume this role
  cross_account_assume_role_policy = try(values.enable_management_integration, false) ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            dependency.argocd.outputs.role_arn,
            dependency.atlantis-management.outputs.role_arn,
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  }) : null

  # Cross-account role policy (what external principals can do)
  cross_account_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeFargateProfile",
          "eks:ListFargateProfiles",
          "eks:DescribeUpdate",
          "eks:ListUpdates"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Describe*",
        ]
        Resource = "*"
      }
    ]
  })

  # ===========================================================================
  # LAUNCH TEMPLATE CONFIGURATION
  # ===========================================================================

  default_ami_id  = try(values.default_ami_id, null)
  default_node_os = try(values.default_node_os, "al2023")
  # generate via aws ssm get-parameter --name "/aws/service/eks/optimized-ami/1.35/amazon-linux-2023/x86_64/standard/recommended/image_id" --region ap-south-1 --query Parameter.Value

  # ===========================================================================
  # SSH KEY CONFIGURATION
  # ===========================================================================

  create_ssh_key = true
  ssh_key_name   = null
  ssh_public_key = null

  # ===========================================================================
  # DEFAULT BLOCK DEVICE CONFIGURATION
  # ===========================================================================

  default_block_device_mappings = [
    {
      device_name           = "/dev/xvda"
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  ]

  # ===========================================================================
  # DEFAULT METADATA OPTIONS (IMDS)
  # ===========================================================================

  default_metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  # ===========================================================================
  # NODE GROUPS CONFIGURATION
  # ===========================================================================

  # system-nodes and generic_compute are always created; monitoring, keymanager
  # and auxillary are created only when their sizing values are provided
  # (standalone stacks may run with just the two base groups).
  node_groups = merge(
    {
      system-nodes = {
        capacity_type  = "ON_DEMAND"
        instance_types = values.system_nodes.instance_types
        subnet_ids     = try(values.eks_workers_subnet_ids, null) != null ? values.eks_workers_subnet_ids : dependency.vpc.outputs.eks_workers_subnet_ids
        desired_size   = values.system_nodes.desired_size
        min_size       = 1
        max_size       = 50
        launch_template = {
          ami_id = try(values.system_nodes.ami_id, null)
        }
        labels = {
          "node-type" = "system-nodes"
        }
      }

      generic_compute = {
        capacity_type  = "ON_DEMAND"
        min_size       = try(values.generic_compute.min_size, 3)
        max_size       = 50
        desired_size   = values.generic_compute.desired_size
        instance_types = values.generic_compute.instance_types
        subnet_ids     = try(values.eks_workers_subnet_ids, null) != null ? values.eks_workers_subnet_ids : dependency.vpc.outputs.eks_workers_subnet_ids
        launch_template = {
          ami_id = try(values.generic_compute.ami_id, null)
        }
        labels = {
          "node-type" = "generic-compute"
        }
      }
    },
    try(values.monitoring, null) != null ? {
      monitoring = {
        capacity_type              = "ON_DEMAND"
        min_size                   = 1
        max_size                   = 50
        desired_size               = values.monitoring.desired_size
        instance_types             = values.monitoring.instance_types
        subnet_ids                 = try(values.eks_workers_subnet_ids, null) != null ? values.eks_workers_subnet_ids : dependency.vpc.outputs.eks_workers_subnet_ids
        max_unavailable_percentage = 1
        launch_template = {
          ami_id = try(values.monitoring.ami_id, null)
        }
        labels = {
          "node-type" = "monitoring"
        }
      }
    } : {},
    try(values.keymanager, null) != null ? {
      keymanager = {
        capacity_type              = "ON_DEMAND"
        min_size                   = 1
        max_size                   = 50
        desired_size               = values.keymanager.desired_size
        instance_types             = values.keymanager.instance_types
        subnet_ids                 = try(values.eks_workers_subnet_ids, null) != null ? values.eks_workers_subnet_ids : dependency.vpc.outputs.eks_workers_subnet_ids
        max_unavailable_percentage = 1
        launch_template = {
          ami_id = try(values.keymanager.ami_id, null)
        }
        labels = {
          "node-type" = "keymanager"
        }
      }
    } : {},
    try(values.auxillary, null) != null ? {
      auxillary = {
        capacity_type              = "ON_DEMAND"
        min_size                   = 0
        max_size                   = 50
        desired_size               = values.auxillary.desired_size
        instance_types             = values.auxillary.instance_types
        subnet_ids                 = try(values.eks_workers_subnet_ids, null) != null ? values.eks_workers_subnet_ids : dependency.vpc.outputs.eks_workers_subnet_ids
        max_unavailable_percentage = 1
        launch_template = {
          ami_id = try(values.auxillary.ami_id, null)
        }
        labels = {
          "node-type" = "auxillary"
        }
      }
    } : {}
  )

  # ===========================================================================
  # EKS ADDONS CONFIGURATION
  # ===========================================================================

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
    "aws-efs-csi-driver" = {
      addon_version        = "v3.0.1-eksbuild.1"
      service_account_role = "efs_csi"
    }
    "snapshot-controller" = {
      addon_version = "v8.3.0-eksbuild.1"
    }
    "metrics-server" = {
      addon_version = "v0.8.0-eksbuild.6"
    }
  }
}
