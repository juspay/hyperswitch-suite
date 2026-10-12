# external-secrets-operator - OCI port of the AWS module of the same name.
# On AWS this is the smallest useful instance of IRSA; NONE of that survives
# structurally. There is no role, no ARN, no assume call and NO service-account
# annotation - on OCI the grant IS the identity. This module renders the
# statements and emits them as `policy_statements`; it does NOT create an
# `oci_identity_policy`.
#
# THE SINGLE MOST DANGEROUS DEFAULT IN THE WHOLE PORT lives on the Kubernetes
# side, not here: ESO's Oracle provider `principalType` defaults to
# `InstancePrincipal`. Omit it and the operator authenticates as the WORKER
# NODE, which usually appears to work while granting every pod on that node the
# same secret access and destroying per-pod audit attribution. See the
# `secret_store_config` output, which exists to make that impossible to forget.

variable "compartment_id" {
  description = "OCID of the environment compartment. The default location term in every rendered statement, and the compartment the consuming shared policy object is attached to. Replaces the AWS module's `region` + `aws_account_id` pair: neither region nor account is part of an OCI IAM grant."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "cluster_ids" {
  description = <<-EOT
    OCIDs of every OKE cluster whose ESO instance this identity serves.

    Replaces the KEYS of the AWS module's `cluster_service_accounts` map, which
    were cluster NAMES resolved through `data.aws_eks_cluster` to an OIDC
    provider ARN. Both data sources disappear: an OCID comes in as an input and
    there is no OIDC provider to register.

    A list from day one. N clusters is N statements in one shared policy object,
    never N objects - a policy name is unique tenancy-wide and NOT updatable, so
    correcting a per-region name later revokes the operator's access mid-flight
    and every ExternalSecret in the cluster stops refreshing.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.cluster_ids) > 0
    error_message = "cluster_ids must contain at least one OKE cluster OCID. An empty list renders statements with no cluster condition, granting every cluster in the tenancy."
  }

  validation {
    condition     = alltrue([for c in var.cluster_ids : can(regex("^ocid1\\.cluster\\.", c))])
    error_message = "every entry in cluster_ids must be an OKE cluster OCID (ocid1.cluster.*)."
  }
}

variable "k8s_namespace" {
  description = "Kubernetes namespace the operator runs in. Half of the `sub` claim on AWS (`system:serviceaccount:<ns>:<name>`), a first-class policy condition here. Flattened from `cluster_service_accounts` to a scalar because the live layer has only ever passed one pair - a capability reduction, and an oracle gate item (check sheet section 8 item 5)."
  type        = string
  default     = "external-secrets-operator"
}

variable "k8s_service_account_name" {
  description = "Service account the operator pod runs as. The other half of the `sub` claim. NOTE: nothing annotates this service account on OCI - the pod side is `serviceAccountName` plus `automountServiceAccountToken: true` and nothing else."
  type        = string
  default     = "external-secrets-sa"
}

variable "vault_id" {
  description = <<-EOT
    OCID of the OCI Vault holding the platform's secrets.

    A NEW REQUIRED INPUT WITH NO AWS COUNTERPART. AWS Secrets Manager is
    implicit per region and account - the AWS module constructs
    `arn:aws:secretsmanager:<region>:<account>:secret:*` and needs no input at
    all. An OCI Vault is an explicit object in an explicit compartment, and
    ESO's `SecretStore` requires its OCID in `spec.provider.oracle.vault`.

    It appears in NO statement. It is passed straight through to the output the
    SecretStore consumes. The grants are compartment-scoped, not vault-scoped.

    This introduces a phase-1 `oci-vault` dependency ahead of a phase-3 unit,
    which is a dependency-phasing change and an oracle gate item (check sheet
    section 8 item 3), NOT YET CONSULTED.
  EOT
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.vault\\.", var.vault_id))
    error_message = "vault_id must be a Vault OCID (ocid1.vault.*). If a mock is flowing through from an unapplied dependency, that is the bug - the operator would be configured against a vault that does not exist."
  }
}

variable "vault_compartment_id" {
  description = "Compartment holding the vault and its secrets. Defaults to compartment_id. If it is OUTSIDE the cluster's compartment subtree, OCI additionally requires an `oci_containerengine_cluster_workload_mapping` - see create_workload_mapping."
  type        = string
  default     = null

  validation {
    condition     = var.vault_compartment_id == null || can(regex("^ocid1\\.(compartment|tenancy)\\.", var.vault_compartment_id))
    error_message = "vault_compartment_id must be a compartment or tenancy OCID."
  }
}

variable "secret_ids" {
  description = <<-EOT
    Optional per-secret least privilege: OCIDs of the individual secrets ESO may
    read. Empty (the default) means compartment-wide, which is exactly the AWS
    behaviour (`secret:*` across the account and region).

    DELIBERATE INVERSION OF THE GCP PRECEDENT. The GCP module offers
    `scope_to_project`, and its own comments warn that `scope_to_project = false`
    with an empty secret list grants nothing and fails every ExternalSecret with
    a non-obvious error. Here that state is unreachable: there is no way to
    configure "no access at all". Oracle gate item (check sheet section 8
    item 6).

    Cost: per-secret scoping is cheap in statement TEXT and expensive in
    statement COUNT - 2 grants x len(secret_ids) x len(cluster_ids) statements
    against a 50-per-policy-object cap. Above roughly 20 secrets it does not
    fit. Check sheet open question 3.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for s in var.secret_ids : can(regex("^ocid1\\.vaultsecret\\.", s))])
    error_message = "every entry in secret_ids must be a Vault secret OCID (ocid1.vaultsecret.*)."
  }
}

variable "create_workload_mapping" {
  description = <<-EOT
    Create an `oci_containerengine_cluster_workload_mapping` per cluster,
    mapping this module's namespace to `vault_compartment_id`.

    Required ONLY when the vault's compartment lies outside the cluster's own
    compartment subtree. With identity-model.md section 4's layout - the cluster
    in `<env>/platform` and the vault in `<env>/data`, both under the
    environment compartment the policy attaches to - it is not needed, and the
    trap is designed out rather than worked around. Hence default false.

    Note the mapping is NAMESPACE-granular only. Oracle: "a workload mapping
    applies to all workloads in the specified namespace on the cluster." The
    `request.principal.service_account` condition in the statement remains the
    sole fine-grained control.
  EOT
  type        = bool
  default     = false
}

variable "additional_grants" {
  description = <<-EOT
    Extra grants beyond the two defaults, in `oke-workload-identity`'s grant
    shape. Replaces AWS `additional_policy_arns` (`[]` in the live unit).

    There are no managed-policy objects on OCI to attach. The nearest thing to
    "a bit more Vault access" is the family resource-type `read secret-family` -
    which is BROADER than the AWS module, because it adds `secret-versions`
    read that the AWS inline policy never granted. Reach for it only
    deliberately.
  EOT
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
}

variable "extra_statements" {
  description = "Raw statement strings appended verbatim. Replaces AWS `additional_assume_role_statements`, and is strictly more capable: `statements` is free-form text, so anything the policy language expresses is reachable. Everything here is re-validated at plan time by the consuming `oke-workload-identity` module's preconditions."
  type        = list(string)
  default     = []
}

variable "shared_statements" {
  description = "Statements produced by the `shared-policy` module for grants used by more than one app. Replaces AWS `customer_managed_policy_arns`: nothing is attachable on OCI, so sharing moves from cloud objects to Terraform text."
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Project name, for naming and tags."
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment short name (dev, integ, sandbox, prod)."
  type        = string
}

variable "region" {
  description = "Region identifier (e.g. ap-mumbai-1). Not part of any IAM grant - it is here because ESO's SecretStore requires `spec.provider.oracle.region`, and because it tags resources."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags, merged over the module's own. The AWS `common_tags` analogue."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "OCI defined tags, keyed \"namespace.key\"."
  type        = map(string)
  default     = {}
}

# DELETED, not accepted as no-ops (so a reader cannot set one and believe it did
# something):
#   role_path             - no role, no path. OCI's organisational axis is the compartment.
#   max_session_duration  - no role, no session. Credential lifetime must now be
#                           bounded on the Kubernetes side or not at all.
#   oidc_audience         - no OIDC provider is registered; there is no `aud`.
#   aws_account_id        - a compartment OCID is not an account ID.
#   role_name / role_description - become the shared policy object's name and description,
#                           which this module does not own.
