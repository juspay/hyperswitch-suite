# ============================================================================
# Istio (GCP equivalent of application-resources/istio)
# ============================================================================
# Same istio-release Helm charts (base/istiod/gateway) as the AWS module,
# installed via the kubernetes/helm providers authenticated against GKE
# instead of EKS. The istio-gateway Service is exposed as a GCP-native L4
# LoadBalancer with a reserved static IP, rather than the AWS module's
# ALB Ingress: GKE's Gateway API resources (the closer analogue to an ALB
# Ingress) are Kubernetes custom resources with no first-class
# hashicorp/kubernetes provider type, so wiring a Gateway/HTTPRoute is left
# to your GitOps/kubectl flow - out of scope for this Terraform module, same
# boundary the rest of this tree draws between infrastructure and
# Kubernetes-native config.
#
# Usage:
#   module "istio" {
#     source = "../../modules/application-resources/istio"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     project_name = "hyperswitch"
#     region       = "europe-west1"
#
#     cluster_name     = module.gke.cluster_name
#     cluster_endpoint = module.gke.endpoint
#     cluster_ca_certificate = module.gke.ca_certificate
#
#     network      = module.vpc_network.network_self_link
#     network_name = module.vpc_network.network_name
#   }
# ============================================================================

provider "kubernetes" {
  host                   = "https://${var.cluster_endpoint}"
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

provider "helm" {
  kubernetes = {
    host                   = "https://${var.cluster_endpoint}"
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    token                  = data.google_client_config.current.access_token
  }
}

# ==============================================================================
# Static IP for the Istio ingress gateway LoadBalancer
# ==============================================================================
resource "google_compute_address" "gateway" {
  count = var.create_gateway_static_ip ? 1 : 0

  project = var.project_id
  name    = "${local.name_prefix}-gateway-ip"
  region  = var.region
}

# ==============================================================================
# Helm Releases
# ==============================================================================
resource "helm_release" "istio_base" {
  count = local.istio_base.enabled ? 1 : 0

  name             = local.istio_base.release_name
  repository       = local.istio_base.chart_repo
  chart            = "base"
  namespace        = var.istio_namespace
  version          = local.istio_base.chart_version
  create_namespace = true
  wait             = true
  force_update     = true

  values = concat(
    [yamlencode({ defaultRevision = "default", base = { enableCRDTemplates = true } })],
    local.istio_base.values_file != "" ? [file(local.istio_base.values_file)] : [],
    local.istio_base.values
  )
}

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

  depends_on = [helm_release.istio_base]
}

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
          type = "LoadBalancer"
          annotations = merge(
            var.create_gateway_static_ip ? {
              "networking.gke.io/load-balancer-type" = "External"
            } : {},
            var.gateway_service_annotations
          )
          loadBalancerIP = var.create_gateway_static_ip ? google_compute_address.gateway[0].address : null
        }
      })
    ],
    local.istio_gateway.values_file != "" ? [file(local.istio_gateway.values_file)] : [],
    local.istio_gateway.values
  )

  depends_on = [helm_release.istiod]
}

# ==============================================================================
# Firewall rule allowing health checks / ingress traffic to the gateway
# ==============================================================================
module "firewall_rules" {
  source = "../../composition/firewall-rules"

  count = var.create_firewall_rules ? 1 : 0

  project_id   = var.project_id
  environment  = var.environment
  project_name = var.project_name
  network_name = var.network_name

  rules = {
    istio-gateway-ingress = {
      rules = [
        {
          name        = "allow-istio-gateway-http"
          description = "Allow HTTP/HTTPS ingress to the Istio gateway"
          direction   = "INGRESS"
          target_tags = ["gke-node"]
          ranges      = ["0.0.0.0/0"]
          allow       = [{ protocol = "tcp", ports = ["80", "443", "15021"] }]
        },
      ]
    }
  }
}
