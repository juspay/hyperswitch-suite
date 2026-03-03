# =============================================================================
# EKS Composition Module - RBAC
# =============================================================================

# -----------------------------------------------------------------------------
# ClusterRole: Developer
# -----------------------------------------------------------------------------
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
    api_groups = ["extensions"]
    resources  = ["ingresses"]
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

  depends_on = [terraform_data.eks_ready]
}

# -----------------------------------------------------------------------------
# ClusterRole: ReadOnly
# -----------------------------------------------------------------------------
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

  depends_on = [terraform_data.eks_ready]
}

# -----------------------------------------------------------------------------
# ClusterRole: CI/CD
# -----------------------------------------------------------------------------
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

  depends_on = [terraform_data.eks_ready]
}

# -----------------------------------------------------------------------------
# Custom RBAC Roles
# -----------------------------------------------------------------------------
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

  depends_on = [terraform_data.eks_ready]
}
