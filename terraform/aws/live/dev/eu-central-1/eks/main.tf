# EKS Cluster - Development Environment
provider "aws" {
  region = var.region
}

module "eks" {
  source = "../../../../modules/composition/eks"

  project_name = var.project_name
  environment  = var.environment

  cluster_version = var.cluster_version
  cluster_name_version = var.cluster_name_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Cluster endpoint access configuration
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Node groups managed independently outside this module for better control
  node_groups = {}

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

# EKS cluster add ons 

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                      = module.eks.cluster_name
  addon_name                        = "vpc-cni"
  addon_version                     = var.eks_addon_versions["vpc-cni"]
  resolve_conflicts_on_create       = "OVERWRITE"
  resolve_conflicts_on_update       = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.custom_nodes
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                      = module.eks.cluster_name
  addon_name                        = "coredns"
  addon_version                     = var.eks_addon_versions["coredns"]
  resolve_conflicts_on_create       = "OVERWRITE"
  resolve_conflicts_on_update       = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.custom_nodes
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                      = module.eks.cluster_name
  addon_name                        = "kube-proxy"
  addon_version                     = var.eks_addon_versions["kube-proxy"]
  resolve_conflicts_on_create       = "OVERWRITE"
  resolve_conflicts_on_update       = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.custom_nodes
  ]
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name                      = module.eks.cluster_name
  addon_name                        = "aws-ebs-csi-driver"
  addon_version                     = var.eks_addon_versions["aws-ebs-csi-driver"]
  service_account_role_arn          = module.eks.ebs_csi_iam_role_arn
  resolve_conflicts_on_create       = "OVERWRITE"
  resolve_conflicts_on_update       = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.custom_nodes
  ]
}

resource "aws_eks_addon" "snapshot_controller" {
  cluster_name                      = module.eks.cluster_name
  addon_name                        = "snapshot-controller"
  addon_version                     = var.eks_addon_versions["snapshot-controller"]
  resolve_conflicts_on_create       = "OVERWRITE"
  resolve_conflicts_on_update       = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.custom_nodes
  ]
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name                      = module.eks.cluster_name
  addon_name                        = "metrics-server"
  addon_version                     = var.eks_addon_versions["metrics-server"]
  resolve_conflicts_on_create       = "OVERWRITE"
  resolve_conflicts_on_update       = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.custom_nodes
  ]
}

# terraform_data to ensure Kubernetes resources are created after cluster is ready
resource "terraform_data" "eks_ready" {
  triggers_replace = [
    module.eks.cluster_id,
    module.eks.cluster_endpoint,
    module.eks.cluster_certificate_authority_data
  ]
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.region
    ]
  }

}

# Helm Provider Configuration
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.region
      ]
    }
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

  depends_on = [terraform_data.eks_ready]
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

  depends_on = [terraform_data.eks_ready]
}

# Hyperswitch Helm Release
# Only deploy if Helm deployments are enabled (not managed by ArgoCD)
resource "helm_release" "hyperswitch_stack" {
  count = var.enable_helm_deployments ? 1 : 0

  name       = "hyperswitch-stack"
  repository = "https://juspay.github.io/hyperswitch-helm"
  chart      = "hyperswitch-stack"
  namespace  = kubernetes_namespace_v1.hyperswitch[0].metadata[0].name

  # Use custom values file for ECR image overrides (if present)
  values = fileexists("${path.module}/hyperswitch-values.yaml") ? [
    file("${path.module}/hyperswitch-values.yaml")
  ] : []

  # Wait for resources to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 900 # 15 minutes

  depends_on = [
    terraform_data.eks_ready,
    kubernetes_namespace_v1.hyperswitch,
    kubernetes_secret_v1.ecr_registry,
    kubernetes_storage_class_v1.ebs_gp3
  ]
}