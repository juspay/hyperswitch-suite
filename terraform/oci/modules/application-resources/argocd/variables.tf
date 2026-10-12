# argocd - the widest identity
# in the platform after `vector`. Three reads before changing anything:
#   1. OCI binds ALL N service accounts here (unlike GCP's 1:1), so
#      `service_accounts` is a list spanning two namespaces.
#   2. NEVER `manage all-resources` - Oracle's tutorial shorthand grants full
#      compartment control; every input that could carry it rejects at plan time.
#   3. THIS MODULE CREATES NO `oci_identity_policy` - it renders statements for
#      the shared oke-workload-identity object. Cross-tenancy Endorse statements
#      are emitted separately (must attach at the tenancy root).

variable "compartment_id" {
  description = "OCID of the environment compartment. Default location term in rendered statements and the attachment point of the consuming shared policy object."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "cluster_ids" {
  description = "OCIDs of the MANAGEMENT OKE cluster(s) ArgoCD itself runs on - not the clusters it deploys into. `request.principal.cluster_id` identifies where the calling pod lives. A list from day one: the policy name is tenancy-unique and non-updatable, so a per-region object is unbuildable at scale."
  type        = list(string)

  validation {
    condition     = length(var.cluster_ids) > 0
    error_message = "cluster_ids must contain at least one OKE cluster OCID."
  }

  validation {
    condition     = alltrue([for c in var.cluster_ids : can(regex("^ocid1\\.cluster\\.", c))])
    error_message = "every entry in cluster_ids must be an OKE cluster OCID (ocid1.cluster.*)."
  }
}

variable "service_accounts" {
  description = <<-EOT
    Every (namespace, name) pair that shares this identity.

    Replaces the AWS module's `argocd_namespace` + `argocd_service_accounts`
    pair, which cannot express two namespaces - the live config's five accounts
    across `argocd` and `argo-workflows` are only representable through the
    generic `cluster_service_accounts` map. Merging them fixes that, and unlike
    GCP every one of them is genuinely bound.

    Statement cost: len(service_accounts) x len(cluster_ids) x len(grants).
    Five accounts and two grants is 10 statements per cluster for this module
    alone, against a 50-per-object cap. Watch it. If pattern-based
    subjects are resolved in favour of pattern values or nested `any{}`, `argocd/*` and
    `argo-workflows/*` collapse to two statements per grant.
  EOT
  type = list(object({
    namespace = string
    name      = string
  }))
  default = [
    { namespace = "argocd", name = "argocd-application-controller" },
    { namespace = "argocd", name = "argocd-server" },
    { namespace = "argocd", name = "argocd-repo-server" },
  ]

  validation {
    condition     = length(var.service_accounts) > 0
    error_message = "service_accounts must contain at least one pair."
  }

  validation {
    condition     = alltrue([for s in var.service_accounts : length(trimspace(s.namespace)) > 0 && length(trimspace(s.name)) > 0])
    error_message = "service_accounts[*].namespace and .name must be non-empty."
  }
}

variable "target_compartment_ids" {
  description = <<-EOT
    Compartments ArgoCD may deploy into. Each yields a `use clusters` statement,
    which covers GenerateClusterKubeconfig.

    THE REPLACEMENT FOR `cross_account_roles`, AND A SECURITY-MODEL CHANGE, NOT
    A RENAME. On AWS the deploy-target boundary is another ACCOUNT; here the
    default is another COMPARTMENT. Compartment isolation is weaker: a parent
    compartment's administrator has full powers over its children, and there is
    no SCP-equivalent a parent cannot override.

    A target outside the cluster's own compartment subtree also needs an
    `oci_containerengine_cluster_workload_mapping` - see
    create_workload_mappings.

    OPEN: whether GenerateClusterKubeconfig is backed
    by a permission inside `use clusters` or only by `manage cluster-family` was
    not read verbatim from the OKE policy reference. If it needs `manage`,
    ArgoCD's grant widens considerably and point 3 in this file's header gets
    harder to hold.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.target_compartment_ids : can(regex("^ocid1\\.compartment\\.", c))])
    error_message = "every entry in target_compartment_ids must be a compartment OCID. `in compartment <name>` is lowercased server-side and produces a perpetual diff."
  }
}

variable "target_cluster_verb" {
  description = "Verb granted on `clusters` in each target compartment. `use` is the intended value and the narrowest that covers kubeconfig generation. Exposed only so this can be answered by configuration rather than by editing the module; `manage` is a materially wider grant and should be a deliberate, reviewed act."
  type        = string
  default     = "use"

  validation {
    condition     = contains(["read", "use", "manage"], var.target_cluster_verb)
    error_message = "target_cluster_verb must be read, use or manage."
  }
}

variable "artifact_compartment_id" {
  description = <<-EOT
    Compartment holding the Helm/manifest artefact buckets ArgoCD reads.
    Replaces `additional_policy_arns = ["...AmazonS3ReadOnlyAccess"]`.

    Null (default) means no object-storage grant at all. Note the substitution
    is strictly NARROWER than the AWS managed policy: `read objects` in one
    compartment, versus account-wide S3 read. That is an improvement, and it can
    break a path that reads from an unexpected bucket.

    If the artefact bucket lives in a `shared` compartment rather than the
    environment compartment, this grant CANNOT go in the environment's shared
    policy object - a policy reaches only its own compartment and descendants,
    and `shared` is a sibling of `dev`, not a child. It needs a SECOND policy
    object attached to `shared`, which costs one more against the 100-object
    tenancy limit. `artifact_statements_are_out_of_subtree` in the outputs flags
    when that is the case.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.artifact_compartment_id == null || can(regex("^ocid1\\.compartment\\.", var.artifact_compartment_id))
    error_message = "artifact_compartment_id must be a compartment OCID."
  }
}

variable "artifact_resource_types" {
  description = "Object-storage resource types granted `read` in artifact_compartment_id. Individual types by default, not the `object-family` aggregate: families are coarser than AWS's curated policies and a reviewer who reaches for the shorter form silently widens access."
  type        = list(string)
  default     = ["objects", "buckets"]
}

variable "cross_tenancy_targets" {
  description = <<-EOT
    Target TENANCIES ArgoCD deploys into. Produces `Define` + `Endorse`
    statements on a SEPARATE output (`cross_tenancy_statements`) which must be
    attached at the MANAGEMENT TENANCY ROOT, with matching `Define` + `Admit`
    in the target tenancy root. Both sides, root compartment only.

    DEFAULTS TO [] AND SHOULD STAY THERE UNTIL RESOLVED. Oracle documents this exact construction with
    `request.principal.type = 'nodepool'`; whether `'workload'` is an accepted
    value is not documented either way. It is the one unverified link in
    ArgoCD's chain, and the fallback if it does not work is a static API key for
    the remote tenancy - reintroducing precisely the long-lived credential this
    port exists to remove, with a bootstrap ordering problem attached (ArgoCD
    would need ESO to get the key; ESO is deployed by ArgoCD).

    Preferred answer, and the reason this defaults empty: keep deploy targets in
    the SAME tenancy in different compartments (`target_compartment_ids`), which
    is fully supported. Under that layout it covers
    dev -> integ -> sandbox with no gap. It does not cover management -> prod,
    which is a tenancy boundary by design.
  EOT
  type = list(object({
    tenancy_ocid = string
    alias        = string
  }))
  default = []

  validation {
    condition     = alltrue([for t in var.cross_tenancy_targets : can(regex("^ocid1\\.tenancy\\.", t.tenancy_ocid))])
    error_message = "cross_tenancy_targets[*].tenancy_ocid must be a tenancy OCID."
  }

  validation {
    condition     = alltrue([for t in var.cross_tenancy_targets : can(regex("^[a-z0-9][a-z0-9-]*$", t.alias))])
    error_message = "cross_tenancy_targets[*].alias must be lowercase alphanumeric with hyphens - it becomes a `Define tenancy <alias> as ...` term and the API normalises case."
  }
}

variable "create_workload_mappings" {
  description = "Create an `oci_containerengine_cluster_workload_mapping` per (cluster x namespace x target compartment outside the cluster's subtree). Off by default: with the recommended flat/nested-under-environment layout the targets are inside the subtree and no mapping is needed. Mappings are namespace-granular only, so they widen reach and never narrow it."
  type        = bool
  default     = false
}

variable "additional_grants" {
  description = "Extra grants in `oke-workload-identity`'s grant shape. Replaces AWS `additional_policy_arns` for anything the two structured inputs above do not cover."
  type = list(object({
    verb           = string
    resource_type  = string
    compartment_id = optional(string)
    condition      = optional(string)
  }))
  default = []

  validation {
    condition     = alltrue([for g in var.additional_grants : contains(["inspect", "read", "use", "manage"], lower(trimspace(g.verb)))])
    error_message = "additional_grants[*].verb must be one of inspect, read, use, manage."
  }

  validation {
    condition     = alltrue([for g in var.additional_grants : lower(trimspace(g.resource_type)) != "all-resources"])
    error_message = "additional_grants[*].resource_type must not be `all-resources`. Oracle's ArgoCD tutorial publishes that statement; it grants ArgoCD full control of the compartment and is far wider than the AWS module it replaces."
  }
}

variable "extra_statements" {
  description = <<-EOT
    Raw statement strings appended verbatim. Replaces AWS
    `additional_assume_role_statements`.

    Note what does NOT need porting into it: the live AWS config's
    self-assumption entry (`ArnLike` on `aws:PrincipalArn`, letting the role
    assume itself) exists to work around AWS's re-assumption path. There is no
    assume step on OCI, so there is nothing to re-enter. That feature is
    delivered by being unnecessary.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for s in var.extra_statements : !can(regex("(?i)all-resources", s))])
    error_message = "extra_statements must not mention `all-resources`. See this file's header, point 2."
  }
}

variable "shared_statements" {
  description = "Statements from the `shared-policy` module. Replaces `customer_managed_policy_arns`: nothing is attachable on OCI, so sharing is text."
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Project name for naming and tags. NOTE: both live AWS roots override this to `management` for this module. That override must survive into OCI naming - the shared policy object's name is tenancy-unique, so two management stacks (sandbox and prod today) whose policies are both called `argocd-management-policy` collide, while `management-<env>-...` does not."
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment short name (dev, integ, sandbox, prod)."
  type        = string
}

variable "region" {
  description = "Region identifier. Not part of any IAM grant; tags and informational output only."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags, merged over the module's own."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "OCI defined tags, keyed \"namespace.key\"."
  type        = map(string)
  default     = {}
}
