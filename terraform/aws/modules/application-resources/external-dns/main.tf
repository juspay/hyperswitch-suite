# ============================================================================
# Data Sources
# ============================================================================

# Get current AWS region
data "aws_region" "current" {}

# Get EKS cluster details
data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}

# Get EKS cluster authentication token
data "aws_eks_cluster_auth" "main" {
  name = var.eks_cluster_name
}

# ============================================================================
# Provider Configuration
# ============================================================================

# Kubernetes provider configuration for managing K8s resources
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

# Helm provider configuration for managing Helm releases
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# ============================================================================
# IAM Role for Service Account (IRSA)
# ============================================================================

# Get OIDC provider for EKS cluster
data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

# Create IAM role for external-dns with IRSA, scoped to the given hosted zone ARNs
module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.name_prefix}-role"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = var.external_dns_hosted_zone_arns

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["${var.external_dns_namespace}:${var.external_dns_service_account_name}"]
    }
  }
}

# ============================================================================
# Kubernetes Service Account
# ============================================================================

# Create Kubernetes service account for external-dns
# This is optional and controlled by var.create_external_dns_service_account
resource "kubernetes_service_account_v1" "external_dns" {
  count = var.create_external_dns_service_account ? 1 : 0

  metadata {
    name      = var.external_dns_service_account_name
    namespace = var.external_dns_namespace

    labels = var.service_account_labels

    # Annotate with IAM role ARN for IRSA
    annotations = merge(var.additional_service_account_annotations, {
      "eks.amazonaws.com/role-arn" = module.external_dns_irsa.iam_role_arn
    })
  }
}

# ============================================================================
# Helm Release
# ============================================================================

# Deploy external-dns using Helm
# This is optional and controlled by var.create_helm_release
resource "helm_release" "external_dns" {
  count = var.create_helm_release ? 1 : 0

  name       = var.helm_release_name
  repository = var.helm_chart_repository
  chart      = "external-dns"
  namespace  = var.external_dns_namespace
  version    = var.external_dns_chart_version
  wait       = true

  # Merge values: base config + custom values file + additional values
  values = concat(
    [
      yamlencode({
        provider = "aws"

        aws = {
          zoneType = var.aws_zone_type
        }

        domainFilters = var.domain_filters

        policy = var.policy

        txtOwnerId = var.txt_owner_id

        extraArgs = var.dry_run ? ["--dry-run"] : []

        serviceAccount = {
          create = false
          name   = var.external_dns_service_account_name
        }
      })
    ],
    var.helm_values_file != "" ? [file(var.helm_values_file)] : [],
    var.helm_chart_values
  )

  depends_on = [kubernetes_service_account_v1.external_dns]
}
