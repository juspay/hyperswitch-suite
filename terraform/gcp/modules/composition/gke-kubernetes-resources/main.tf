# =============================================================================
# GKE Kubernetes Resources Module (GCP equivalent of composition/eks-kubernetes-resources)
# =============================================================================
# Manages Kubernetes resources that require an operational GKE cluster. Like
# its AWS counterpart, this must be applied *after* composition/gke, passing
# through the cluster's connection details, since the kubernetes/helm
# providers need a live endpoint to plan against.
#
# Divergences from the AWS module, both intentional:
#   - No self-hosted cluster-autoscaler Deployment/ECR-image-sync machinery:
#     GKE's autoscaler is a control-plane feature enabled directly on
#     composition/gke (cluster_autoscaling / node pool min/max counts), not
#     something deployed as a workload here.
#   - No ECR-style registry pull secret: Artifact Registry access from GKE
#     is granted via Workload Identity on the node/GSA (roles/artifactregistry.reader),
#     so no docker imagePullSecret is normally required. An optional secret
#     is still supported for non-GCP registries.
#
# Usage:
#   module "gke_kubernetes_resources" {
#     source = "../../modules/composition/gke-kubernetes-resources"
#
#     cluster_name     = module.gke.cluster_name
#     cluster_endpoint = module.gke.endpoint
#     cluster_ca_certificate = module.gke.ca_certificate
#     ...
#   }
# =============================================================================

resource "terraform_data" "cluster_ready" {
  triggers_replace = [
    var.cluster_name,
    var.cluster_endpoint,
    var.cluster_ca_certificate,
  ]

  lifecycle {
    precondition {
      condition     = var.cluster_endpoint != null && var.cluster_endpoint != ""
      error_message = "cluster_endpoint must be provided and non-empty. The GKE cluster must exist before creating Kubernetes resources."
    }
    precondition {
      condition     = var.cluster_ca_certificate != null && var.cluster_ca_certificate != ""
      error_message = "cluster_ca_certificate must be provided. The GKE cluster must exist before creating Kubernetes resources."
    }
  }
}

# -----------------------------------------------------------------------------
# Kubernetes / Helm Provider Configuration
# -----------------------------------------------------------------------------
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

# =============================================================================
# RBAC Resources
# =============================================================================

resource "kubernetes_cluster_role_v1" "developer" {
  count = var.create_default_rbac_roles ? 1 : 0

  metadata {
    name = "cluster-developer"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "pods/exec", "pods/portforward", "services", "endpoints", "persistentvolumeclaims", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [terraform_data.cluster_ready]
}

resource "kubernetes_cluster_role_v1" "readonly" {
  count = var.create_default_rbac_roles ? 1 : 0

  metadata {
    name = "cluster-readonly"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "endpoints", "persistentvolumeclaims", "configmaps", "secrets", "namespaces", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [terraform_data.cluster_ready]
}

resource "kubernetes_cluster_role_v1" "cicd" {
  count = var.create_default_rbac_roles ? 1 : 0

  metadata {
    name = "cluster-cicd"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "endpoints", "persistentvolumeclaims", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list", "watch", "create"]
  }

  depends_on = [terraform_data.cluster_ready]
}

resource "kubernetes_cluster_role_v1" "custom_roles" {
  for_each = var.custom_rbac_roles

  metadata {
    name = "cluster-${each.key}"
  }

  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups     = rule.value.api_groups
      resources      = rule.value.resources
      verbs          = rule.value.verbs
      resource_names = try(rule.value.resource_names, [])
    }
  }

  depends_on = [terraform_data.cluster_ready]
}

# =============================================================================
# Storage Class Resources
# =============================================================================

resource "kubernetes_storage_class_v1" "pd_balanced" {
  count = var.create_default_storage_class ? 1 : 0

  metadata {
    name = var.default_storage_class_name
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type = "pd-balanced"
  }

  depends_on = [terraform_data.cluster_ready]
}

resource "kubernetes_storage_class_v1" "custom" {
  for_each = var.custom_storage_classes

  metadata {
    name        = each.key
    annotations = each.value.annotations
  }

  storage_provisioner    = each.value.storage_provisioner
  volume_binding_mode    = each.value.volume_binding_mode
  reclaim_policy         = each.value.reclaim_policy
  allow_volume_expansion = each.value.allow_volume_expansion
  parameters             = each.value.parameters

  depends_on = [terraform_data.cluster_ready]
}

# =============================================================================
# Kubernetes Namespace Resources
# =============================================================================

resource "kubernetes_namespace_v1" "hyperswitch" {
  count = var.enable_helm_deployments ? 1 : 0

  metadata {
    name = var.hyperswitch_namespace

    labels = {
      name        = var.hyperswitch_namespace
      environment = var.environment
    }
  }

  depends_on = [terraform_data.cluster_ready]
}

# -----------------------------------------------------------------------------
# Optional registry pull secret (only needed for non-Artifact-Registry images;
# Artifact Registry access is normally granted via Workload Identity instead)
# -----------------------------------------------------------------------------
resource "kubernetes_secret_v1" "registry_pull_secret" {
  count = var.enable_helm_deployments && var.create_registry_pull_secret ? 1 : 0

  metadata {
    name      = "registry-pull-secret"
    namespace = kubernetes_namespace_v1.hyperswitch[0].metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.registry_pull_secret_server) = {
          username = var.registry_pull_secret_username
          password = var.registry_pull_secret_password
          auth     = base64encode("${var.registry_pull_secret_username}:${var.registry_pull_secret_password}")
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
    terraform_data.cluster_ready,
    kubernetes_namespace_v1.hyperswitch,
    kubernetes_storage_class_v1.pd_balanced,
  ]
}
