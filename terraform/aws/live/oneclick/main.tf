terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  backend "local" {}
}

provider "aws" {
  region = var.aws_region
}

module "hyperswitch" {
  source = "../../modules/hyperswitch-oneclick"

  aws_region   = var.aws_region
  project_name = var.project_name
  environment  = var.environment

  vpc_cidr = var.vpc_cidr

  availability_zones = var.availability_zones

  cluster_version = var.cluster_version

  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_enabled_log_types            = var.cluster_enabled_log_types
  cluster_log_retention_days           = var.cluster_log_retention_days

  addon_versions = var.addon_versions

  node_group = var.node_group

  hyperswitch_namespace    = var.hyperswitch_namespace
  hyperswitch_release_name = var.hyperswitch_release_name
  hyperswitch_helm_version = var.hyperswitch_helm_version
  hyperswitch_helm_values  = var.hyperswitch_helm_values

  tags = var.tags
}
