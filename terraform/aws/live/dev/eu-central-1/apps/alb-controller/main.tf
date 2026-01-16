# ============================================================================
# AWS Load Balancer Controller - Dev Environment
# ============================================================================
# This configuration deploys the AWS Load Balancer Controller:
#   - IAM role for service accounts (IRSA) for the controller
#   - Kubernetes service account with IAM role annotation
#   - Helm release for the AWS Load Balancer Controller
#
# The controller enables Kubernetes Ingress resources to provision AWS ALBs
# and Services of type LoadBalancer to provision NLBs automatically.
# ============================================================================

provider "aws" {
  region = var.region
}

# Data source to get EKS cluster details
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "hyperswitch-dev-terraform-state"
    key    = "dev/eu-central-1/eks/terraform.tfstate"
    region = "eu-central-1"
  }
}

module "aws_load_balancer_controller" {
  source = "../../../../../modules/application-resources/alb-controller"

  # Environment & Project Configuration
  region       = var.region
  environment  = var.environment
  project_name = var.project_name

  # EKS Cluster Configuration
  eks_cluster_name = data.terraform_remote_state.eks.outputs.cluster_name

  # ALB Controller Configuration
  alb_controller_namespace              = var.alb_controller_namespace
  alb_controller_service_account_name   = var.alb_controller_service_account_name
  create_alb_controller_service_account = var.create_alb_controller_service_account

  # Helm Release Configuration
  create_helm_release          = var.create_helm_release
  alb_controller_chart_version = var.alb_controller_chart_version
  helm_release_name            = var.helm_release_name
  helm_chart_repository        = var.helm_chart_repository
  helm_chart_values            = var.helm_chart_values
  helm_values_file             = var.helm_values_file

  # Service Account Configuration
  service_account_labels                 = var.service_account_labels
  additional_service_account_annotations = var.additional_service_account_annotations

  # Tags
  common_tags = var.common_tags
}
