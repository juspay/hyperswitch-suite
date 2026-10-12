# Workload identity for the card-vault pod. THIS FILE CREATES NO RESOURCES, by
# design: OCI has no role object - identity is OKE Workload Identity, one policy
# statement whose four `where` conditions (principal type, namespace, service
# account, cluster id) ARE the security boundary.
#
# Structural facts that make a resource here the wrong answer:
#   1. oci_identity_policy.name is tenancy-unique and non-updatable, and the
#      tenancy limit is 100 policy objects, so the platform has exactly ONE
#      policy per environment into which every module contributes statements.
#   2. A copy-pasted statement that drops a condition fails OPEN - missing
#      cluster_id grants every cluster, missing service_account grants every pod
#      in the namespace, both accepted silently. So statement TEXT is rendered
#      in exactly one module and never here.
#
# This module exports `workload_grants`, consumed by oke-workload-identity. The
# AWS role ARN is not reproduced because OCI needs no service-account
# annotation, only serviceAccountName + automountServiceAccountToken: true.

locals {
  # Grant 1+2 - read the database credential from Vault. BOTH statements are
  # needed: `read secrets` returns METADATA only; reading the VALUE is `read
  # secret-bundles`. Scoped per-secret with `target.secret.id` so the grant
  # reaches only the card vault's own credential. Written pre-normalised (no
  # spaces around `=`) because a spaced form produces a permanent server-side
  # diff.
  secret_read_grants = local.db_secret_id == null ? [] : [
    for verb_resource in ["secret-bundles", "secrets"] : {
      namespace       = var.k8s_namespace
      service_account = var.k8s_service_account_name
      verb            = "read"
      resource_type   = verb_resource
      compartment_id  = coalesce(var.workload_grant_compartment_id, var.compartment_id)
      condition       = "target.secret.id='${local.db_secret_id}'"
    }
  ]

  # Grant 3 - crypto operations on the locker's own key. OPT-IN, DEFAULT OFF:
  # hyperswitch-card-vault compiles only kms-aws / kms-hashicorp-vault features,
  # so there is no confirmed way for the running app to use an OCI key, and an
  # unusable grant is the kind of surplus permission this port is meant to
  # remove. Turn on only once the app can speak to OCI KMS. NOTE the per-key
  # condition `target.key.id` is unconfirmed - confirm before enabling.
  key_use_grants = (var.grant_workload_key_usage && local.key_id != null) ? [
    {
      namespace       = var.k8s_namespace
      service_account = var.k8s_service_account_name
      verb            = "use"
      resource_type   = "keys"
      compartment_id  = coalesce(var.workload_grant_compartment_id, var.compartment_id)
      condition       = "target.key.id='${local.key_id}'"
    }
  ] : []

  workload_grants = concat(local.secret_read_grants, local.key_use_grants)
}
