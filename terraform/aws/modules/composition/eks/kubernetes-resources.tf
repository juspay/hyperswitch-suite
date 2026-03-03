# =============================================================================
# EKS Composition Module - Kubernetes Resources
# =============================================================================

# -----------------------------------------------------------------------------
# Default StorageClass for EBS volumes
# -----------------------------------------------------------------------------
resource "kubernetes_storage_class_v1" "ebs_gp3" {
  count = var.create_default_storage_class ? 1 : 0

  metadata {
    name = var.default_storage_class_name
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

# -----------------------------------------------------------------------------
# Kubernetes Namespaces
# -----------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "hyperswitch" {
  count = var.enable_helm_deployments ? 1 : 0

  metadata {
    name = var.hyperswitch_namespace

    labels = {
      name        = var.hyperswitch_namespace
      environment = var.environment
    }
  }

  depends_on = [terraform_data.eks_ready]
}

# -----------------------------------------------------------------------------
# ECR Registry Secret for pulling images
# -----------------------------------------------------------------------------
data "aws_ecr_authorization_token" "token" {
  count = var.enable_helm_deployments && var.create_ecr_registry_secret ? 1 : 0
}

resource "kubernetes_secret_v1" "ecr_registry" {
  count = var.enable_helm_deployments && var.create_ecr_registry_secret ? 1 : 0

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

# -----------------------------------------------------------------------------
# Hyperswitch Helm Release
# -----------------------------------------------------------------------------
resource "helm_release" "hyperswitch_stack" {
  count = var.enable_helm_deployments ? 1 : 0

  name       = var.hyperswitch_release_name
  repository = var.hyperswitch_helm_repository
  chart      = var.hyperswitch_helm_chart
  namespace  = kubernetes_namespace_v1.hyperswitch[0].metadata[0].name
  version    = var.hyperswitch_chart_version

  values = var.hyperswitch_values_file != null ? [
    file(var.hyperswitch_values_file)
  ] : []

  wait          = true
  wait_for_jobs = true
  timeout       = var.hyperswitch_helm_timeout

  depends_on = [
    terraform_data.eks_ready,
    kubernetes_namespace_v1.hyperswitch,
    kubernetes_secret_v1.ecr_registry,
    kubernetes_storage_class_v1.ebs_gp3
  ]
}
