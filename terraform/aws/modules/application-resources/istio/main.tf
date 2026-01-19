# ============================================================================
# Data Sources
# ============================================================================

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

# Kubernetes provider configuration
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
# Security Group Creation
# ============================================================================

resource "aws_security_group" "lb_security_group" {
  count = var.create_lb_security_group ? 1 : 0

  name        = "${local.name_prefix}-lb-sg"
  description = "Security group for Istio Gateway Load Balancer"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}

# ============================================================================
# Helm Release
# ============================================================================

# Helm release for Istio base components
resource "helm_release" "istio_base" {
  count = local.istio_base.enabled ? 1 : 0

  name             = local.istio_base.release_name
  repository       = local.istio_base.chart_repo
  chart            = "base"
  namespace        = var.istio_namespace
  version          = local.istio_base.chart_version
  create_namespace = true
  wait             = true
  # Force replace CRDs on upgrade to avoid conflicts
  force_update = true
  values = concat(
    [
      yamlencode({
        defaultRevision = "default"
        # Ensure CRDs are managed by this release
        base = {
          enableCRDTemplates = true
        }
      })
    ],
    local.istio_base.values_file != "" ? [file(local.istio_base.values_file)] : [],
    local.istio_base.values
  )
}

# Helm release for Istio control plane (istiod)
resource "helm_release" "istiod" {
  count = local.istiod.enabled ? 1 : 0

  name       = local.istiod.release_name
  repository = local.istiod.chart_repo
  chart      = "istiod"
  namespace  = var.istio_namespace
  version    = local.istiod.chart_version
  wait       = true

  values = concat(
    local.istiod.values_file != "" ? [file(local.istiod.values_file)] : [],
    local.istiod.values
  )

  depends_on = [
    helm_release.istio_base
  ]
}

# Helm release for Istio ingress gateway
resource "helm_release" "istio_gateway" {
  count = local.istio_gateway.enabled ? 1 : 0

  name       = local.istio_gateway.release_name
  repository = local.istio_gateway.chart_repo
  chart      = "gateway"
  namespace  = var.istio_namespace
  version    = local.istio_gateway.chart_version
  wait       = true

  values = concat(
    [
    yamlencode({
      service = {
        type = "ClusterIP"
        annotations = {}
      }
    })
    ],
    local.istio_gateway.values_file != "" ? [file(local.istio_gateway.values_file)] : [],
    local.istio_gateway.values
  )

  depends_on = [
    helm_release.istiod
  ]
}

# ============================================================================
# Kubernetes Ingress
# ============================================================================

# Ingress resource for Istio Gateway
resource "kubernetes_ingress_v1" "istio_gateway" {
  count = local.istio_gateway.enabled ? 1 : 0

  metadata {
    name      = "${local.istio_gateway.release_name}-ingress"
    namespace = var.istio_namespace
    annotations = merge(
      local.ingress_annotations,
      var.ingress_annotations
    )
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = local.istio_gateway.release_name
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/healthz/ready"
          path_type = "Prefix"

          backend {
            service {
              name = local.istio_gateway.release_name
              port {
                number = 15021
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.istio_gateway
  ]
}
