# =============================================================================
# OKE Kubernetes Resources Module - equivalent of the AWS
# eks-kubernetes-resources composition module. Applied separately from the
# OKE cluster itself for the same reason as the AWS module: the
# kubernetes/helm providers need a live cluster endpoint to initialize.
# =============================================================================

# -----------------------------------------------------------------------------
# Kubernetes/Helm provider auth - equivalent of AWS's
# data.aws_eks_cluster_auth + static token. OCI's standard pattern is an
# exec-based token fetched via the `oci` CLI (oci ce cluster generate-token),
# since there's no direct Terraform data-source analog to
# aws_eks_cluster_auth's short-lived static token.
# -----------------------------------------------------------------------------
resource "terraform_data" "cluster_ready" {
  triggers_replace = [
    var.cluster_id,
    var.cluster_endpoint,
    var.cluster_certificate_authority_data,
  ]

  lifecycle {
    precondition {
      condition     = var.cluster_endpoint != null && var.cluster_endpoint != ""
      error_message = "Cluster endpoint must be provided and non-empty. The OKE cluster must exist before creating Kubernetes resources."
    }
  }
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "oci"
    args        = ["ce", "cluster", "generate-token", "--cluster-id", var.cluster_id, "--region", var.region]
  }
}

provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "oci"
      args        = ["ce", "cluster", "generate-token", "--cluster-id", var.cluster_id, "--region", var.region]
    }
  }
}

# =============================================================================
# RBAC Resources (unchanged from AWS - fully cloud-agnostic)
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
      resource_names = rule.value.resource_names
    }
  }

  depends_on = [terraform_data.cluster_ready]
}

# =============================================================================
# Storage Class Resources - provisioner changed from ebs.csi.aws.com to
# OCI's Block Volume CSI driver (bundled with OKE by default)
# =============================================================================
resource "kubernetes_storage_class_v1" "oci_bv" {
  count = var.create_default_storage_class ? 1 : 0

  metadata {
    name = var.default_storage_class_name
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "blockvolume.csi.oraclecloud.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    "attachment-type" = "paravirtualized"
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
# Cluster Autoscaler - runs with --cloud-provider=oci; node pools are
# discovered by explicit OCID + min/max (var.cluster_autoscaler_node_pools),
# the OKE equivalent of AWS's ASG tag-based auto-discovery
# =============================================================================
locals {
  cluster_autoscaler_sa_name = coalesce(var.cluster_autoscaler_service_account_name, "${var.environment}-${var.project_name}-cluster-autoscaler")

  cluster_autoscaler_nodepool_args = [
    for np in var.cluster_autoscaler_node_pools :
    "--nodes=${np.min_size}:${np.max_size}:${np.node_pool_id}"
  ]
}

# Instance-principal auth is used instead of Workload Identity/IRSA here for
# simplicity, since the cluster autoscaler needs tenancy-wide node-pool
# read/scale permissions, not a single namespace-scoped identity. Attach the
# dynamic-group/policy pair below to the node pool running this workload, or
# switch to OKE Workload Identity (matching AWS IRSA more closely) if
# per-service-account scoping is required.
resource "oci_identity_dynamic_group" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  compartment_id = data.oci_containerengine_cluster.this.compartment_id
  name           = "${var.environment}-${var.project_name}-cluster-autoscaler-dynamic-group"
  description    = "Dynamic group for the OKE cluster autoscaler"
  matching_rule  = "ALL {resource.type = 'cluster', resource.id = '${var.cluster_id}'}"
}

resource "oci_identity_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  compartment_id = data.oci_containerengine_cluster.this.compartment_id
  name           = "${var.environment}-${var.project_name}-cluster-autoscaler-policy"
  description    = "Policy for the OKE cluster autoscaler to manage node pool sizing"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.cluster_autoscaler[0].name} to manage cluster-node-pools in compartment id ${data.oci_containerengine_cluster.this.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.cluster_autoscaler[0].name} to use instances in compartment id ${data.oci_containerengine_cluster.this.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.cluster_autoscaler[0].name} to use subnets in compartment id ${data.oci_containerengine_cluster.this.compartment_id}",
  ]
}

data "oci_containerengine_cluster" "this" {
  cluster_id = var.cluster_id
}

resource "kubernetes_service_account_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name      = local.cluster_autoscaler_sa_name
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "app"       = "cluster-autoscaler"
    }
  }

  depends_on = [terraform_data.cluster_ready]
}

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
    api_groups = ["apps"]
    resources  = ["statefulsets", "replicasets", "daemonsets"]
    verbs      = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["watch", "list"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
    verbs      = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["batch"]
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
}

resource "kubernetes_deployment_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels    = { "app" = "cluster-autoscaler" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { "app" = "cluster-autoscaler" }
    }

    template {
      metadata {
        labels = { "app" = "cluster-autoscaler" }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "8085"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.cluster_autoscaler[0].metadata[0].name

        container {
          name  = "cluster-autoscaler"
          image = var.cluster_autoscaler_image

          command = concat(
            ["./cluster-autoscaler"],
            ["--v=2", "--stderrthreshold=info", "--cloud-provider=oci", "--leader-elect=false"],
            local.cluster_autoscaler_nodepool_args,
          )

          resources {
            requests = {
              cpu    = coalesce(var.cluster_autoscaler_resources.requests_cpu, "100m")
              memory = coalesce(var.cluster_autoscaler_resources.requests_memory, "600Mi")
            }
            limits = {
              cpu    = coalesce(var.cluster_autoscaler_resources.limits_cpu, "100m")
              memory = coalesce(var.cluster_autoscaler_resources.limits_memory, "600Mi")
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
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_account_v1.cluster_autoscaler,
    kubernetes_cluster_role_binding_v1.cluster_autoscaler,
  ]
}

# =============================================================================
# Kubernetes Namespace + OCIR registry secret + Hyperswitch Helm release
# (unchanged from AWS aside from ECR -> OCIR)
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

resource "kubernetes_secret_v1" "ocir_registry" {
  count = var.enable_helm_deployments && var.create_ocir_registry_secret ? 1 : 0

  metadata {
    name      = "ocir-registry-secret"
    namespace = kubernetes_namespace_v1.hyperswitch[0].metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.ocir_server) = {
          username = var.ocir_username
          password = var.ocir_auth_token
          auth     = base64encode("${var.ocir_username}:${var.ocir_auth_token}")
        }
      }
    })
  }

  depends_on = [kubernetes_namespace_v1.hyperswitch]
}

resource "helm_release" "hyperswitch_stack" {
  count = var.enable_helm_deployments ? 1 : 0

  name       = var.hyperswitch_release_name
  repository = var.hyperswitch_helm_repository
  chart      = var.hyperswitch_helm_chart
  namespace  = kubernetes_namespace_v1.hyperswitch[0].metadata[0].name
  version    = var.hyperswitch_chart_version

  values = var.hyperswitch_values_file != null ? [file(var.hyperswitch_values_file)] : []

  wait          = true
  wait_for_jobs = true
  timeout       = var.hyperswitch_helm_timeout

  depends_on = [
    terraform_data.cluster_ready,
    kubernetes_namespace_v1.hyperswitch,
    kubernetes_secret_v1.ocir_registry,
    kubernetes_storage_class_v1.oci_bv,
  ]
}
