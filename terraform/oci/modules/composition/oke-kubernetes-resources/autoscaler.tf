# Cluster Autoscaler (OCI cloudprovider) - in-cluster add-on
#
# Static --nodes=<min>:<max>:<pool-OCID> per pool, rendered from the oke
# module's node_pool_autoscaler_bounds output, so adding a pool re-renders this
# deployment in the same apply.
#
# IAM half (OCI API access, not RBAC): the CAS pod uses the worker node's
# INSTANCE PRINCIPAL. The phase-0 IAM bootstrap must create a dynamic group and
# attach the six statements (manage cluster-node-pools, manage instance-family,
# use subnets, read virtual-network-family, use vnics, inspect compartments).
#
# Drift: this module must NOT touch pool size at all - oke routes autoscaler
# pools to ignore_initial_pool_size so a terragrunt apply does not revert the
# CAS's scale actions. This file is the "external enforcer" half.

locals {
  # Stable ordering for --nodes flags (sorted by pool name) so plan diffs are stable.
  cluster_autoscaler_nodes_flags = var.enable_cluster_autoscaler ? [
    for pool_name in sort(keys(var.cluster_autoscaler_node_pools)) :
    "${var.cluster_autoscaler_node_pools[pool_name].min_size}:${var.cluster_autoscaler_node_pools[pool_name].max_size}:${var.cluster_autoscaler_node_pools[pool_name].pool_id}"
  ] : []
}

# -----------------------------------------------------------------------------
# ServiceAccount (kube-system)
# -----------------------------------------------------------------------------
resource "kubernetes_service_account_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "app"       = "cluster-autoscaler"
    }
  }

  # No AWS-style IRSA annotation: OKE auth is the node's instance principal, not a per-SA role.
  depends_on = [terraform_data.cluster_ready]
}

# -----------------------------------------------------------------------------
# ClusterRole / ClusterRoleBinding - Kubernetes-side permissions are cloud-agnostic;
# OCI-API access is IAM, not RBAC.
# -----------------------------------------------------------------------------
resource "kubernetes_cluster_role_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name = "cluster-autoscaler"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "app"       = "cluster-autoscaler"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["events", "endpoints"]
    verbs      = ["create", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/eviction"]
    verbs      = ["create"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups     = [""]
    resources      = ["endpoints"]
    resource_names = ["cluster-autoscaler"]
    verbs          = ["get", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["watch", "list", "get", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["extensions", "apps"]
    resources  = ["replicasets", "daemonsets", "statefulsets"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["watch", "list"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities", "volumeattachments"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["resource.k8s.io"]
    resources  = ["resourceslices", "deviceclasses", "resourceclaims"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["batch", "extensions"]
    resources  = ["jobs"]
    verbs      = ["get", "list", "watch", "patch"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["create"]
  }

  rule {
    api_groups     = ["coordination.k8s.io"]
    resources      = ["leases"]
    resource_names = ["cluster-autoscaler"]
    verbs          = ["get", "update"]
  }

  depends_on = [terraform_data.cluster_ready]
}

resource "kubernetes_cluster_role_binding_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name = "cluster-autoscaler"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "app"       = "cluster-autoscaler"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.cluster_autoscaler[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.cluster_autoscaler[0].metadata[0].name
    namespace = "kube-system"
  }

  depends_on = [
    kubernetes_service_account_v1.cluster_autoscaler,
    kubernetes_cluster_role_v1.cluster_autoscaler
  ]
}

# -----------------------------------------------------------------------------
# Role / RoleBinding (kube-system, for the status configmap)
# -----------------------------------------------------------------------------
resource "kubernetes_role_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "app"       = "cluster-autoscaler"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "list", "watch"]
  }

  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
    verbs          = ["delete", "get", "update", "watch"]
  }

  depends_on = [terraform_data.cluster_ready]
}

resource "kubernetes_role_binding_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "app"       = "cluster-autoscaler"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.cluster_autoscaler[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.cluster_autoscaler[0].metadata[0].name
    namespace = "kube-system"
  }

  depends_on = [
    kubernetes_service_account_v1.cluster_autoscaler,
    kubernetes_role_v1.cluster_autoscaler
  ]
}

# -----------------------------------------------------------------------------
# Deployment
# -----------------------------------------------------------------------------
resource "kubernetes_deployment_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "app" = "cluster-autoscaler"
    }
  }

  spec {
    # Oracle explicitly recommends never running a single replica of CA.
    replicas = var.cluster_autoscaler_replicas

    selector {
      match_labels = {
        "app" = "cluster-autoscaler"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "cluster-autoscaler"
        }
        annotations = merge(
          {
            "prometheus.io/scrape" = "true"
            "prometheus.io/port"   = "8085"
          },
          var.cluster_autoscaler_pod_annotations
        )
      }

      spec {
        service_account_name = kubernetes_service_account_v1.cluster_autoscaler[0].metadata[0].name

        container {
          name  = "cluster-autoscaler"
          image = var.cluster_autoscaler_image

          # Oracle's recommended OCI arg set plus the --nodes flags; no --cloud-config,
          # no --cluster-name, no vertical-mode flags (unsupported on OCI).
          command = concat(
            ["./cluster-autoscaler"],
            [
              "--v=4",
              "--stderrthreshold=info",
              "--cloud-provider=oci",
              "--max-node-provision-time=25m",
              "--scale-down-delay-after-add=10m",
              "--scale-down-unneeded-time=10m",
              "--unremovable-node-recheck-timeout=5m",
              "--balance-similar-node-groups",
              "--balancing-ignore-label=displayName",
              "--balancing-ignore-label=hostname",
              "--balancing-ignore-label=internal_addr",
              "--balancing-ignore-label=oci.oraclecloud.com/fault-domain",
            ],
            concat(
              [for f in local.cluster_autoscaler_nodes_flags : "--nodes=${f}"],
              var.cluster_autoscaler_extra_args
            )
          )

          # Instance-principal auth: canonical env var plus the deprecated alias still read.
          # Workload identity is the better-scoped follow-up.
          env {
            name  = "OCI_USE_INSTANCE_PRINCIPAL"
            value = "true"
          }
          env {
            name  = "OKE_USE_INSTANCE_PRINCIPAL"
            value = "true"
          }
          env {
            name  = "OCI_SDK_APPEND_USER_AGENT"
            value = "oci-oke-cluster-autoscaler"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "300Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "300Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health-check"
              port = 8085
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health-check"
              port = 8085
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }
        }

        dynamic "toleration" {
          for_each = var.cluster_autoscaler_tolerations
          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = try(toleration.value.value, null)
            effect   = toleration.value.effect
          }
        }

        node_selector = var.cluster_autoscaler_node_selector
      }
    }
  }

  depends_on = [
    kubernetes_service_account_v1.cluster_autoscaler,
    kubernetes_cluster_role_binding_v1.cluster_autoscaler,
    kubernetes_role_binding_v1.cluster_autoscaler
  ]
}