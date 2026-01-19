# ============================================================================
# Istio - Dev Environment
# ============================================================================
# This configuration deploys Istio service mesh components:
#   - Istio Base: CRDs and base components
#   - Istiod: Control plane for service mesh
#   - Istio Gateway: Ingress gateway with ClusterIP service
#   - Kubernetes Ingress: ALB ingress with health checks
#   - Security Group: Optional load balancer security group
#
# The ingress resource automatically provisions an AWS ALB for external traffic.
# ============================================================================

provider "aws" {
  region = var.region
}

module "istio" {
  source = "../../../../../modules/application-resources/istio"

  # Environment & Project Configuration
  region       = var.region
  environment  = var.environment
  project_name = var.project_name

  vpc_id = var.vpc_id
  lb_subnet_ids = var.lb_subnet_ids

  # EKS Cluster Configuration
  eks_cluster_name = var.eks_cluster_name

  create_lb_security_group = var.create_lb_security_group
  lb_security_groups      = var.lb_security_groups

  istio_namespace = var.istio_namespace

  create_helm_releases = var.create_helm_releases

  istio_base = var.istio_base
  istiod = var.istiod
  istio_gateway = var.istio_gateway

  ingress_annotations = var.ingress_annotations

  # Tags
  common_tags = var.common_tags
}
