# OKE Kubernetes Resources - cluster access bindings (Phase 2)
#
# The `kubernetes` provider needs the live cluster's endpoint + CA before it can
# plan; the OKE cluster (oci/oke) is phase 1, this is phase 2. The
# terraform_data.cluster_ready precondition below fails plans loudly when the
# cluster is not there yet. With cluster_access_bindings = {} the for_each
# filters produce zero resources and the module plans as a clean no-op.

# -----------------------------------------------------------------------------
# Cluster-readiness gate
# -----------------------------------------------------------------------------
resource "terraform_data" "cluster_ready" {
  triggers_replace = [
    var.cluster_id,
    var.cluster_endpoint,
    var.cluster_ca_cert,
  ]

  lifecycle {
    precondition {
      condition     = var.cluster_endpoint != null && var.cluster_endpoint != ""
      error_message = "cluster_endpoint must be provided and non-empty. The OKE cluster (oci/oke) must exist before creating Kubernetes resources."
    }
    precondition {
      condition     = var.cluster_ca_cert != null && var.cluster_ca_cert != ""
      error_message = "cluster_ca_cert must be provided and non-empty. The OKE cluster (oci/oke) must exist before creating Kubernetes resources."
    }
    precondition {
      condition     = var.cluster_id != null && var.cluster_id != ""
      error_message = "cluster_id must be provided and non-empty. The OKE cluster (oci/oke) must exist before creating Kubernetes resources."
    }
    # Cross-variable guard for the Cluster Autoscaler (autoscaler.tf): enabling it
    # without an image or a node-pools map would render --nodes garbage or deploy nothing.
    precondition {
      condition     = !var.enable_cluster_autoscaler || (var.cluster_autoscaler_image != null && length(var.cluster_autoscaler_node_pools) > 0)
      error_message = "enable_cluster_autoscaler = true requires both cluster_autoscaler_image and a non-empty cluster_autoscaler_node_pools map."
    }
  }
}

# -----------------------------------------------------------------------------
# Kubernetes Provider Configuration
# -----------------------------------------------------------------------------
# OKE auth is an OCI-signed exec credential, not a static token. The exec block
# runs `oci ce cluster generate-token` exactly as kubectl does.
#
# Runner prerequisites:
#   - `oci` CLI installed and authenticated.
#   - `use clusters` IAM permission for the caller's principal.
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_cert)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "oci"
    args = [
      "ce", "cluster", "generate-token",
      "--cluster-id", var.cluster_id,
      "--region", var.region,
    ]
  }
}

# -----------------------------------------------------------------------------
# Cluster Access Bindings - the IAM -> Kubernetes RBAC subject mapping
# -----------------------------------------------------------------------------
# Each entry becomes ONE ClusterRoleBinding (scope_kind = "cluster") or ONE
# RoleBinding (scope_kind = "namespace"). The subject OCID is the IAM principal
# OKE authenticates, mapped onto a Kubernetes User or Group by OCID.
# Namespace-scoped role_ref.kind = "ClusterRole" is valid and preferred when
# granting a built-in cluster role.
resource "kubernetes_cluster_role_binding_v1" "cluster_access" {
  for_each = {
    for name, binding in var.cluster_access_bindings :
    name => binding
    if binding.scope_kind == "cluster" && length(binding.subjects) > 0
  }

  metadata {
    name        = each.key
    annotations = var.annotations
    labels      = var.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = each.value.role_ref.kind
    name      = each.value.role_ref.name
  }

  dynamic "subject" {
    for_each = each.value.subjects
    content {
      api_group = subject.value.api_group
      kind      = subject.value.kind
      name      = subject.value.name
      namespace = try(subject.value.namespace, null)
    }
  }

  depends_on = [terraform_data.cluster_ready]
}

resource "kubernetes_role_binding_v1" "cluster_access" {
  for_each = {
    for name, binding in var.cluster_access_bindings :
    name => binding
    if binding.scope_kind == "namespace" && length(binding.subjects) > 0
  }

  metadata {
    name        = each.key
    namespace   = each.value.namespace
    annotations = var.annotations
    labels      = var.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = each.value.role_ref.kind
    name      = each.value.role_ref.name
  }

  dynamic "subject" {
    for_each = each.value.subjects
    content {
      api_group = subject.value.api_group
      kind      = subject.value.kind
      name      = subject.value.name
      namespace = try(subject.value.namespace, null)
    }
  }

  depends_on = [terraform_data.cluster_ready]
}
