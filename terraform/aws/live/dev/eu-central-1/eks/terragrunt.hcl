include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../..//modules/composition/eks"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id                       = "vpc-XXXXXXXXXXXXXXXXX"
    eks_workers_subnet_ids       = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-YYYYYYYYYYYYYYYYY"]
    eks_control_plane_subnet_ids = ["subnet-ZZZZZZZZZZZZZZZZZ", "subnet-WWWWWWWWWWWWWWWWW"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

locals {
  cluster_iam_role_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::XXXXXXXXXXXX:role/argocd-management-role" }
        Action    = "sts:AssumeRole"
      },
    ]
  })

  node_group_iam_role_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
    ]
  })

  node_group_custom_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
          "tag:GetResources",
        ]
        Resource = "*"
      },
    ]
  })

  cross_account_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = ["arn:aws:iam::XXXXXXXXXXXX:role/argocd-management-role"] }
        Action    = "sts:AssumeRole"
      },
    ]
  })

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
          "eks:ListUpdates",
        ]
        Resource = "*"
      },
    ]
  })
}

inputs = {
  project_name         = include.root.locals.project_name
  environment          = include.root.locals.environment.short
  region               = include.root.locals.region
  cluster_version      = "1.35"
  cluster_name_version = "01"
  tags                 = include.root.locals.tags

  vpc_id                   = dependency.vpc.outputs.vpc_id
  subnet_ids               = dependency.vpc.outputs.eks_workers_subnet_ids
  control_plane_subnet_ids = dependency.vpc.outputs.eks_control_plane_subnet_ids

  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = concat(include.root.locals.office_ips, include.root.locals.vpn_cidr_blocks)
  vpn_cidr_blocks                      = concat(include.root.locals.office_ips, include.root.locals.vpn_cidr_blocks)

  cluster_access_entries = {
    admin_sso_role = {
      principal_arn = "arn:aws:iam::${include.root.locals.account_id}:role/aws-reserved/sso.amazonaws.com/${include.root.locals.region}/AWSReservedSSO_AWSAdministratorAccess_XXXXXXXXXXXXXXXX"
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
    "arn:aws:iam::${include.root.locals.account_id}:role/aws-reserved/sso.amazonaws.com/${include.root.locals.region}/AWSReservedSSO_AWSAdministratorAccess_XXXXXXXXXXXXXXXX",
  ]

  create_cluster_iam_role             = true
  cluster_iam_role_assume_role_policy = local.cluster_iam_role_assume_role_policy
  cluster_iam_role_policies = {
    AmazonEKSClusterPolicy = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  }
  cluster_custom_policy_json = null

  create_node_group_iam_role             = true
  node_group_iam_role_assume_role_policy = local.node_group_iam_role_assume_role_policy
  node_group_custom_policy_json          = local.node_group_custom_policy_json
  node_group_iam_role_policies = {
    AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AWSXrayFullAccess                  = "arn:aws:iam::aws:policy/AWSXrayFullAccess"
    CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  create_cross_account_role        = true
  cross_account_assume_role_policy = local.cross_account_assume_role_policy
  cross_account_policy_json        = local.cross_account_policy_json

  default_ami_id = "ami-XXXXXXXXXXXXXXXXX"

  create_ssh_key = true
  ssh_key_name   = null
  ssh_public_key = null

  default_block_device_mappings = [
    {
      device_name           = "/dev/xvda"
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    },
  ]

  default_metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  node_groups = {
    system_nodes = {
      capacity_type  = "SPOT"
      instance_types = ["t3.medium"]
      subnet_ids     = [dependency.vpc.outputs.eks_workers_subnet_ids[0]]

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
}
