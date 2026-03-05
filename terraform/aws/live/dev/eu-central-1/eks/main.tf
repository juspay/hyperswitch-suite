# =============================================================================
# EKS Cluster - Dev Environment (eks-03)
# =============================================================================
# This is a thin wrapper around the EKS composition module.
# All configuration values are passed via terraform.tfvars.
# JSON policies are defined in locals (jsonencode cannot be used in tfvars).
# =============================================================================

# AWS Provider Configuration
provider "aws" {
  region = var.region
}

terraform {
  # Backend Configuration
  backend "s3" {
    bucket  = "hyperswitch-dev-terraform-state"
    key     = "dev/eu-central-1/eks/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# =============================================================================
# Local Values - JSON Policies (jsonencode cannot be used in tfvars)
# =============================================================================
locals {
  # Cluster IAM Role Assume Role Policy
  # EKS service + ArgoCD from management cluster
  cluster_iam_role_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::XXXXXXXXXXXX:role/argocd-management-role"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # Node Group IAM Role Assume Role Policy
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

  # Node Group Custom Policy (Observability)
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
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })

  # Cross-Account Role Assume Role Policy
  # ArgoCD, Atlantis from management cluster
  cross_account_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::XXXXXXXXXXXX:role/argocd-management-role",
            # "arn:aws:iam::XXXXXXXXXXXX:role/atlantis-role",
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # Cross-Account Role Policy (what external principals can do)
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
      }
    ]
  })
}

# =============================================================================
# EKS Composition Module
# =============================================================================
module "eks" {
  source = "../../../../modules/composition/eks"

  # Core Configuration
  project_name         = var.project_name
  environment          = var.environment
  cluster_name_version = var.cluster_name_version
  cluster_version      = var.cluster_version
  region               = var.region
  tags                 = var.tags

  # Networking
  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  # Cluster Endpoint Access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  vpn_cidr_blocks                      = var.vpn_cidr_blocks

  # Cluster Access
  cluster_access_entries = var.cluster_access_entries
  kms_key_administrators = var.kms_key_administrators

  # Cluster IAM Role Configuration (using locals for JSON policies)
  create_cluster_iam_role             = var.create_cluster_iam_role
  cluster_iam_role_arn                = var.cluster_iam_role_arn
  cluster_iam_role_name               = var.cluster_iam_role_name
  cluster_iam_role_assume_role_policy = local.cluster_iam_role_assume_role_policy
  cluster_iam_role_policies           = var.cluster_iam_role_policies
  cluster_custom_policy_json          = var.cluster_custom_policy_json

  # Node Group IAM Role Configuration (using locals for JSON policies)
  create_node_group_iam_role             = var.create_node_group_iam_role
  node_group_iam_role_arn                = var.node_group_iam_role_arn
  node_group_iam_role_name               = var.node_group_iam_role_name
  node_group_iam_role_assume_role_policy = local.node_group_iam_role_assume_role_policy
  node_group_iam_role_policies           = var.node_group_iam_role_policies
  node_group_custom_policy_json          = local.node_group_custom_policy_json

  # Cross-Account Role Configuration (using locals for JSON policies)
  create_cross_account_role        = var.create_cross_account_role
  cross_account_role_name          = var.cross_account_role_name
  cross_account_assume_role_policy = local.cross_account_assume_role_policy
  cross_account_policy_json        = local.cross_account_policy_json
  cross_account_policy_arns        = var.cross_account_policy_arns

  # Node Groups
  node_groups = var.node_groups

  # Launch Template Configuration
  default_ami_id                = var.default_ami_id
  default_block_device_mappings = var.default_block_device_mappings
  default_metadata_options      = var.default_metadata_options
  custom_userdata_template_path = var.custom_userdata_template_path

  # SSH Key Configuration
  create_ssh_key = var.create_ssh_key
  ssh_key_name   = var.ssh_key_name
  ssh_public_key = var.ssh_public_key

  # EKS Addons
  eks_addons = var.eks_addons
}
