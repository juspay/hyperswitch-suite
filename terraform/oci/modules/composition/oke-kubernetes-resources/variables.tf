variable "cluster_id" {
  description = "OCID of the OKE cluster. From the oke composition module's cluster_id output. Used both as a readiness gate and for the kubernetes provider's exec credential."
  type        = string
}

variable "cluster_endpoint" {
  description = "The single endpoint a Kubernetes provider should target: the OKE module's cluster_endpoint output (already https://-prefixed, public if the control plane is public, otherwise private)."
  type        = string
}

variable "cluster_ca_cert" {
  description = "Base64-encoded cluster CA certificate. From the oke composition module's cluster_ca_cert output."
  type        = string
}

variable "region" {
  description = "OCI region (e.g. ap-mumbai-1). Used as the --region argument to the OKE exec credential."
  type        = string
}

# scope_kind: "cluster" (ClusterRoleBinding) or "namespace" (RoleBinding).
# A subject's kind is "User" or "Group" and the name is that principal's OCID.
# The kind MUST match the OCID prefix - a mismatch creates a binding matching
# no-one, silently.
variable "cluster_access_bindings" {
  description = <<EOT
Map of cluster access bindings, analogous to AWS's cluster_access_entries.

    "ketu-cluster-admin" = {
      scope_kind = "cluster"           # ClusterRoleBinding
      role_ref   = { name = "cluster-admin", kind = "ClusterRole" }
      subjects = [
        { kind = "Group", name = "ocid1.group.oc1.aaaaaaaae26f..." }  # group OCID matches AWS SSO group semantics
      ]
    }

    "reliability-scorecard-integ" = {
      scope_kind = "namespace"          # RoleBinding - mirrors AWS access_scope.type = "namespace"
      namespace  = "hyperswitch-integ"
      role_ref   = { name = "edit", kind = "ClusterRole" }            # valid: ClusterRole scoped to the namespace
      subjects = [
        { kind = "Group", name = "ocid1.group.oc1....." }
      ]
    }
  EOT

  type = map(object({
    scope_kind = string
    namespace  = optional(string)
    role_ref = object({
      name = string
      kind = string
    })
    subjects = list(object({
      kind      = string
      name      = string
      api_group = optional(string, "rbac.authorization.k8s.io")
      namespace = optional(string)
    }))
  }))

  default = {}

  # scope_kind must be "cluster" or "namespace"
  validation {
    condition = alltrue([
      for name, b in var.cluster_access_bindings :
      contains(["cluster", "namespace"], b.scope_kind)
    ])
    error_message = "Every cluster_access_bindings entry must set scope_kind to \"cluster\" or \"namespace\"."
  }

  # namespace required only when scope_kind = "namespace"; forbidden otherwise
  validation {
    condition = alltrue([
      for name, b in var.cluster_access_bindings :
      (b.scope_kind == "namespace" && try(b.namespace, null) != null && b.namespace != "")
      || (b.scope_kind == "cluster" && (try(b.namespace, null) == null || b.namespace == ""))
    ])
    error_message = "A namespace is required when scope_kind = \"namespace\", and must be omitted when scope_kind = \"cluster\"."
  }

  # role_ref.kind must match scope_kind (ClusterRole valid in namespace scope too)
  validation {
    condition = alltrue([
      for name, b in var.cluster_access_bindings :
      (b.role_ref.kind == "ClusterRole") || (b.scope_kind == "namespace" && b.role_ref.kind == "Role")
    ])
    error_message = "role_ref.kind must be \"ClusterRole\", or \"Role\" when scope_kind is \"namespace\"."
  }

  # subject kind must be User or Group; api_group defaults to rbac.authorization.k8s.io
  validation {
    condition = alltrue([
      for name, b in var.cluster_access_bindings :
      alltrue([for s in b.subjects : contains(["User", "Group"], s.kind)])
    ])
    error_message = "Every subject must be kind \"User\" or \"Group\" (OKE maps OCI IAM User OCIDs and Group OCIDs)."
  }

  # THE silent trap: kind must match the OCID prefix, or the binding matches no-one.
  validation {
    condition = alltrue([
      for name, b in var.cluster_access_bindings :
      alltrue([
        for s in b.subjects :
        (s.kind == "User" && can(regex("^ocid1\\.user\\.", s.name))) ||
        (s.kind == "Group" && can(regex("^ocid1\\.group\\.", s.name)))
      ])
    ])
    error_message = "Every subject's name must be an OCI OCID matching its kind: User -> ocid1.user.oc1..*; Group -> ocid1.group.oc1..*. A mismatch binds no identity (silent no-access)."
  }
}

# Labels/annotations added to every binding
variable "labels" {
  description = "Labels added to every ClusterRoleBinding/RoleBinding metadata (typical freeform_tags analog: project, environment, managed_by)."
  type        = map(string)
  default     = {}
}

variable "annotations" {
  description = "Annotations added to every ClusterRoleBinding/RoleBinding metadata."
  type        = map(string)
  default     = {}
}

# Cluster Autoscaler (OCI cloudprovider) - in-cluster add-on, gated off by default.
variable "enable_cluster_autoscaler" {
  description = "Whether to deploy the Cluster Autoscaler (OCI cloudprovider) as an in-cluster workload. When false (default) no CAS resources are created."
  type        = bool
  default     = false
}

variable "cluster_autoscaler_node_pools" {
  description = <<EOT
Map of node pool name -> { min_size, max_size, pool_id } the Cluster Autoscaler
should manage. Fed from the oke module's `node_pool_autoscaler_bounds` output
(via the catalog unit), so adding a pool to oke re-renders the deployment's
--nodes flags in the same apply.

Pool OCIDs are runtime values (they only exist after oke is applied), so in a
fresh-tree terragrunt plan they come from the dependency's mock_outputs (the
same mock OCID pattern the cluster_id/endpoint/CA use). Required whenever
enable_cluster_autoscaler = true; an enabled-but-empty map is a hard error
(a missing bound would render `--nodes=::ocid`).
  EOT
  type = map(object({
    min_size = number
    max_size = number
    pool_id  = string
  }))
  default = {}

  # min/max/pool_id all mandatory, min <= max (hard error, not silent skip)
  validation {
    condition = alltrue([
      for name, p in var.cluster_autoscaler_node_pools :
      p.min_size != null && p.max_size != null && p.pool_id != null &&
      p.pool_id != "" && p.min_size >= 0 && p.max_size >= p.min_size
    ])
    error_message = "Every cluster_autoscaler_node_pools entry needs min_size >= 0, max_size >= min_size, and a non-empty pool_id (pool OCID)."
  }
}

variable "cluster_autoscaler_image" {
  description = "CAS container image (OCI cloudprovider build, e.g. a regional OCIR copy like bom.ocir.io/<tenancy-namespace>/oci-cluster-autoscaler:1.34.3-323). Required when enable_cluster_autoscaler = true; no default is guessed because the tag is coupled to the cluster's kubernetes minor version."
  type        = string
  default     = null
}

variable "cluster_autoscaler_replicas" {
  description = "Replicas of the CAS deployment. Oracle explicitly recommends never running a single replica; default 2."
  type        = number
  default     = 2
}

variable "cluster_autoscaler_node_selector" {
  description = "node_selector pinning the CAS pod to a particular pool (e.g. the system pool). Critical for dev: the CAS must not run on the very pool it scales down."
  type        = map(string)
  default     = {}
}

variable "cluster_autoscaler_tolerations" {
  description = "Tolerations for the CAS pod (mirrors the AWS module's cluster_autoscaler_tolerations)."
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}

variable "cluster_autoscaler_pod_annotations" {
  description = "Extra pod annotations merged over the default prometheus scrape ones."
  type        = map(string)
  default     = {}
}

variable "cluster_autoscaler_extra_args" {
  description = "Extra command-line args appended to the CAS deployment command (after the base OCI arg set and the --nodes flags)."
  type        = list(string)
  default     = []
}
