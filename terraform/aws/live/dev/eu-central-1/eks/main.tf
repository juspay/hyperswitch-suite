# EKS Cluster - Development Environment
provider "aws" {
  region = var.region
}

module "eks" {
  source = "../../../../modules/composition/eks"

  project_name = var.project_name
  environment  = var.environment

  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  node_groups = var.node_groups

  # VPN access configuration
  vpn_cidr_blocks = var.vpn_cidr_blocks

  # ArgoCD assume role configuration
  argocd_assume_role_principal_arn = var.argocd_assume_role_principal_arn

  # Cluster access entries
  cluster_access_entries = merge(var.cluster_access_entries, {
      "argo_cross_account" = {
        principal_arn = aws_iam_role.argocd_cross_account.arn
        type          = "STANDARD"

        policy_associations = {
          cluster_admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
  })

  tags = var.tags
}

# Data sources for EKS cluster authentication
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name

  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name

  depends_on = [module.eks]
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.cluster.endpoint, "")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), "")
  token                  = try(data.aws_eks_cluster_auth.cluster.token, "")
}

# Helm Provider Configuration
provider "helm" {
  kubernetes = {
    host                   = try(data.aws_eks_cluster.cluster.endpoint, "")
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), "")
    token                  = try(data.aws_eks_cluster_auth.cluster.token, "")
  }
}

# Kubernetes namespace for Hyperswitch
# Only create if Helm deployments are enabled
resource "kubernetes_namespace_v1" "hyperswitch" {
  count = var.enable_helm_deployments ? 1 : 0

  metadata {
    name = "hyperswitch"

    labels = {
      name        = "hyperswitch"
      environment = var.environment
    }
  }

  depends_on = [module.eks]
}

# Data source to get ECR authorization token
# Only needed if Helm deployments are enabled
data "aws_ecr_authorization_token" "token" {
  count = var.enable_helm_deployments ? 1 : 0
}

# ECR Registry Secret for pulling images
# Only create if Helm deployments are enabled
resource "kubernetes_secret_v1" "ecr_registry" {
  count = var.enable_helm_deployments ? 1 : 0

  metadata {
    name      = "ecr-registry-secret"
    namespace = kubernetes_namespace_v1.hyperswitch[0].metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${data.aws_ecr_authorization_token.token[0].proxy_endpoint}" = {
          auth = data.aws_ecr_authorization_token.token[0].authorization_token
        }
      }
    })
  }

  depends_on = [kubernetes_namespace_v1.hyperswitch]
}

# Default StorageClass for EBS volumes
resource "kubernetes_storage_class_v1" "ebs_gp3" {
  metadata {
    name = "ebs-gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [module.eks]
}

# Hyperswitch Helm Release
# Only deploy if Helm deployments are enabled (not managed by ArgoCD)
resource "helm_release" "hyperswitch_stack" {
  count = var.enable_helm_deployments ? 1 : 0

  name       = "hyperswitch-stack"
  repository = "https://juspay.github.io/hyperswitch-helm"
  chart      = "hyperswitch-stack"
  namespace  = kubernetes_namespace_v1.hyperswitch[0].metadata[0].name

  # Use custom values file for ECR image overrides
  values = [
    file("${path.module}/hyperswitch-values.yaml")
  ]

  # Wait for resources to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 900 # 15 minutes

  depends_on = [
    module.eks,
    kubernetes_namespace_v1.hyperswitch,
    kubernetes_secret_v1.ecr_registry,
    kubernetes_storage_class_v1.ebs_gp3
  ]
}