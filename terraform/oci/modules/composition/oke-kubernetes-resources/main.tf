# =============================================================================
# OKE Kubernetes Resources - cluster access bindings (Phase 2)
# =============================================================================
# Port of terraform/aws/modules/composition/eks-kubernetes-resources's
# `cluster_access_entries` feature (the AWS parity contract; the parent OCI
# module check sheet is docs/multi-cloud-parity/oci/modules/eks.md gap 4.2,
# verdict SUBSTITUTE). Oracle gate verdict: APPROVED WITH CORRECTIONS, recorded
# inline and in oci/oke/iam.tf + eks.md §8 item 2 crossrefs.
#
# First-cut scope: this file holds the kubernetes ClusterRoleBinding/RoleBinding
# resources (cluster_access_entries parity). The Cluster Autoscaler add-on
# lives in autoscaler.tf (AWS feature 7 parity, oracle-gated). Default RBAC
# ClusterRoles and storage classes are still out of scope (the oracle gate
# explicitly said do not add `create_default_rbac_roles` in this cut), as is
# the helm-managed hyperswitch release.
#
# WHY A SEPARATE MODULE: the `kubernetes` provider needs the live cluster's
# endpoint + CA before it can plan. Exactly like AWS `eks` ->
# `eks-kubernetes-resources` and GCP `gke` -> `gke-kubernetes-resources`, the
# OKE cluster (oci/oke) is phase 1 and this is phase 2. The
# terraform_data.cluster_ready precondition below fails plans loudly when the
# cluster is not there yet.
#
# A none-op: with cluster_access_bindings = {} the for_each filters produce
# zero resources and the module plans cleanly, so phase 2 can apply before any
# bindings exist. (Oracle gate correction #3.)
#
# The IAM half ("may this principal call `oci ce cluster generate-token`", an
# `oci_identity_policy` `Allow group <g> to use clusters in compartment <c>`)
# is NOT here: per oci/oke/iam.tf feature 4 it belongs to the phase-0 IAM
# bootstrap. A binding without it produces a working kubeconfig that 401s on
# the first API call.
# =============================================================================
# required_version / required_providers for this module are declared in
# versions.tf. See that file for the oracle/oci and hashicorp/kubernetes pins.
# =============================================================================

# -----------------------------------------------------------------------------
# Cluster-readiness gate
# -----------------------------------------------------------------------------
# Mirror of AWS's terraform_data.cluster_ready (same role as the AWS check -
# the OKE module can emit a fresh cluster_id endpoint while the control plane
# is briefly unreachable after creation). Also serves as the blow-up point for
# the chicken-and-egg: the runner of the first apply needs `use clusters` IAM
# access itself to even generate a token - which the caller is expected to
# already have via the bootstrap (tenancy Administrators group members are
# auto-granted cluster-admin by OCI itself - that's the dev bootstrap path the
# Oracle gate maintained).
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
    # Cross-variable guard for the Cluster Autoscaler (autoscaler.tf): enabling
    # it without an image or without a node-pools map would render --nodes=::ocid
    # garbage or deploy nothing. Precondition (not a check block, which only
    # warns on Terraform >=1.5) so it hard-fails the plan. Oracle gate Q5.
    precondition {
      condition     = !var.enable_cluster_autoscaler || (var.cluster_autoscaler_image != null && length(var.cluster_autoscaler_node_pools) > 0)
      error_message = "enable_cluster_autoscaler = true requires both cluster_autoscaler_image and a non-empty cluster_autoscaler_node_pools map."
    }
  }
}

# -----------------------------------------------------------------------------
# Kubernetes Provider Configuration
# -----------------------------------------------------------------------------
# DIVERGENCE from the AWS module (verified in the Oracle gate): AWS used a
# STATIC token via data.aws_eks_cluster_auth.cluster.token. OCI OKE has no
# equivalent static-token data source - auth is an OCI-signed exec credential.
# The `exec` block runs `oci ce cluster generate-token` exactly as kubectl does
# (captured verbatim from the live dev kubeconfig's `user-<id>` exec stanza: no
# --profile, no --auth - those fall back to the runner's default OCI config).
# This is deliberately visible here instead of hiding behind a kubeconfig string.
#
# Runner prerequisites (see oracle gate B + iam.tf feature 4):
#   - `oci` CLI installed and authenticated for the caller (`auth security_token`
#     for humans in dev; `auth instance_principal` for CI once gap 4.3 rules).
#   - `use clusters` IAM permission for the caller's principal -
#     identity-model.md's `GenerateClusterKubeconfig` operation.
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

# =============================================================================
# Cluster Access Bindings - the IAM -> Kubernetes RBAC subject mapping
# =============================================================================
# Each `cluster_access_bindings` entry becomes ONE ClusterRoleBinding (for
# scope_kind = "cluster") or ONE RoleBinding (for scope_kind = "namespace").
# AWS's single cluster_access_entries object splits into cluster-wide vs
# namespace-scoped bindings here, mirroring access_scope.type in eks-01. The
# subject OCID is the IAM principal OKE authenticates and maps directly onto a
# Kubernetes User or Group by OCID - this is the documented OCI mechanism
# (oci.aboutaccesscontrol's create clusterrolebinding --user=<OCID> recipe).
#
# Namespace-scoped role_ref.kind = "ClusterRole" is valid and preferred when
# the granting is a builtins cluster role (mirroring AWS's
# AmazonEKSClusterAdminPolicy vs namespace-scoped AmazonEKSEditPolicy).
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
