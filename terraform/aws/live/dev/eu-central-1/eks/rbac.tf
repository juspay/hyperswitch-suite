# ============================================
# Kubernetes RBAC - Cluster-Wide Roles
# ============================================
#
# This file defines cluster-wide RBAC roles with different permission levels.
# These roles can be bound to IAM users/roles via ClusterRoleBindings.
#
# ROLE SUMMARY:
# 1. cluster-developer   - Full access to workloads (deploy, scale, debug)
# 2. cluster-readonly    - View-only access to all resources
# 3. cluster-cicd        - CI/CD automation (deploy, update, limited access)
#
# HOW TO USE:
# 1. Apply this Terraform to create the ClusterRoles
# 2. Create ClusterRoleBindings to grant IAM users/roles access
# 3. Map IAM roles to Kubernetes users via EKS access entries
#
# MAPPING IAM TO KUBERNETES:
# When you add an IAM principal via EKS access_entries, it maps to a Kubernetes user.
# The username format is typically: arn:aws:iam::ACCOUNT:role/ROLE_NAME
#
# Then bind that user to a ClusterRole using ClusterRoleBinding (see examples below)
#
# ============================================

# ============================================
# Developer Role - Full access to workloads
# ============================================
resource "kubernetes_cluster_role_v1" "developer" {
  metadata {
    name = "cluster-developer"
  }

  # Deployments, ReplicaSets, StatefulSets, DaemonSets
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # Pods - full access including exec and logs
  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "pods/exec"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # Services, ConfigMaps, Secrets
  rule {
    api_groups = [""]
    resources  = ["services", "configmaps", "secrets", "persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # Jobs, CronJobs
  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # Ingress
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # HorizontalPodAutoscalers
  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # Namespaces - read only
  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list", "watch"]
  }

  # Events - read only
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [terraform_data.eks_ready]
}

# ============================================
# Read-Only Role - View all resources
# ============================================
resource "kubernetes_cluster_role_v1" "readonly" {
  metadata {
    name = "cluster-readonly"
  }

  # All core resources - read only
  rule {
    api_groups = [""]
    resources = [
      "pods", "pods/log",
      "services",
      "configmaps",
      "persistentvolumeclaims",
      "namespaces",
      "events",
      "nodes"
    ]
    verbs = ["get", "list", "watch"]
  }

  # Apps resources - read only
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch"]
  }

  # Batch resources - read only
  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  # Networking - read only
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  # Autoscaling - read only
  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [terraform_data.eks_ready]
}

# ============================================
# CI/CD Role - Automated deployment access
# ============================================
resource "kubernetes_cluster_role_v1" "cicd" {
  metadata {
    name = "cluster-cicd"
  }

  # Deployments - full access for rolling updates
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # Pods - limited access (read + delete for forced restarts)
  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log"]
    verbs      = ["get", "list", "watch", "delete"]
  }

  # Services and ConfigMaps
  rule {
    api_groups = [""]
    resources  = ["services", "configmaps"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  # Secrets - read only (should be managed separately)
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list"]
  }

  # Jobs for one-off tasks
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["get", "list", "watch", "create", "delete"]
  }

  # Namespaces - read only
  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list"]
  }

  depends_on = [terraform_data.eks_ready]
}

# ============================================
# ClusterRoleBindings - Map IAM to K8s Roles
# ============================================

# Example: Bind a user to Developer role
# Uncomment and modify the examples below to grant access

# resource "kubernetes_cluster_role_binding_v1" "developer_example" {
#   metadata {
#     name = "developer-binding-example"
#   }
#
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role_v1.developer.metadata[0].name
#   }
#
#   subject {
#     kind      = "User"
#     name      = "developer-user"  # Replace with actual IAM role/user
#     api_group = "rbac.authorization.k8s.io"
#   }
#
#   depends_on = [kubernetes_cluster_role_v1.developer]
# }

# resource "kubernetes_cluster_role_binding_v1" "readonly_example" {
#   metadata {
#     name = "readonly-binding-example"
#   }
#
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role_v1.readonly.metadata[0].name
#   }
#
#   subject {
#     kind      = "User"
#     name      = "readonly-user"  # Replace with actual IAM role/user
#     api_group = "rbac.authorization.k8s.io"
#   }
#
#   depends_on = [kubernetes_cluster_role_v1.readonly]
# }

# resource "kubernetes_cluster_role_binding_v1" "cicd_example" {
#   metadata {
#     name = "cicd-binding-example"
#   }
#
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role_v1.cicd.metadata[0].name
#   }
#
#   subject {
#     kind      = "User"
#     name      = "cicd-serviceaccount"  # Replace with actual IAM role for CI/CD
#     api_group = "rbac.authorization.k8s.io"
#   }
#
#   depends_on = [kubernetes_cluster_role_v1.cicd]
# }
