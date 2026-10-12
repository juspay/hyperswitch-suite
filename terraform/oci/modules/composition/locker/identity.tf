# =============================================================================
# Workload identity for the card-vault pod (check sheet features 7-10)
# =============================================================================
# THIS FILE CREATES NO RESOURCES, AND THAT IS THE POINT.
#
# AWS features 7-10 are an IAM role, an instance profile, three custom policies
# and an escape hatch for extra attachments. All four are SUBSTITUTE on OCI,
# and the substitution is decided centrally, not here:
# docs/multi-cloud-parity/oci/identity-model.md selects OKE Workload Identity,
# and there is NO ROLE OBJECT in that model. A grant is a single policy
# statement whose four `where` conditions - principal type, namespace, service
# account, cluster id - ARE the security boundary.
#
# Two structural facts make a resource here the wrong answer:
#
#   1. `oci_identity_policy.name` is unique across the ENTIRE TENANCY and is
#      NOT UPDATABLE, and the tenancy limit is 100 policy objects. One object
#      per app per live root is 12 apps x 11 roots = 132 - unbuildable. So the
#      platform has exactly ONE policy object per environment
#      (application-resources/oke-workload-identity), into which every module
#      contributes STATEMENTS.
#   2. A copy-pasted IRSA block that drops a condition fails CLOSED on AWS. A
#      copy-pasted OCI statement that drops a condition fails OPEN - a
#      statement missing `request.principal.cluster_id` grants every cluster in
#      the tenancy, and one missing `request.principal.service_account` grants
#      every pod in the namespace, both accepted by the API without error. So
#      statement TEXT is rendered in exactly one module and nowhere else, and
#      no `request.principal` literal appears in this file.
#
# What this module exports instead is the `workload_grants` output: structured
# grant objects in exactly the shape oke-workload-identity's `workload_grants`
# variable takes. The catalog wires them together. That output is this module's
# replacement for the AWS module's role ARN, and it is deliberately NOT
# annotatable onto a Kubernetes service account - OCI needs no annotation at
# all, only `serviceAccountName` plus `automountServiceAccountToken: true` in
# the pod spec.
#
# WHAT THE AWS BUNDLE GRANTED AND WHAT IS DELIBERATELY DROPPED (check sheet
# section 4.3 and the "Access control" row of section 10, which records the AWS
# side as the WEAKER one and instructs the port to tighten rather than
# replicate):
#
#   AmazonS3FullAccess (AWS-managed)  -> DROPPED. Full read/write to every
#       bucket in the account, from a card-data-handling instance. Nothing in
#       the card vault's function needs it. If an object-storage need is ever
#       identified, it gets its own grant scoped with
#       `target.bucket.name='<one bucket>'`.
#   ecr:* on Resource:"*"             -> DROPPED. Image pull on OKE is a
#       node-level concern (instance principal / image pull secret), not a
#       workload-identity one. A `read repos` grant here would authorise the
#       POD to pull any image in the tenancy, which is not what the AWS rule
#       was for.
#   CloudWatchAgentServerPolicy       -> DROPPED with the VM tier; see
#       logging.tf.
#   locker_logs (scoped log write)    -> DROPPED with the VM tier; the pod logs
#       to stdout and vector collects it.
#   AmazonSSMManagedInstanceCore      -> DROPPED. This was the interactive
#       access path; its OCI analogue is the Bastion service, which is an
#       operator identity, not a workload one.
#   locker_kms (KMS crypto ops)       -> OPT-IN, default OFF. See below.

locals {
  # ---------------------------------------------------------------------------
  # Grant 1+2 - read the database credential from Vault.
  #
  # The direct counterpart of the GCP module's
  # roles/secretmanager.secretAccessor binding on the locker service account.
  #
  # BOTH statements are needed and the difference is a documented trap:
  # `read secrets` returns METADATA ONLY (GetSecret, ListSecrets). Reading the
  # VALUE is `read secret-bundles` (GetSecretBundle). `secret-family` would
  # cover both but also grants secret-versions, which is broader than the AWS
  # baseline. identity-model.md section 3.5.
  #
  # Scoped per-secret with `target.secret.id`, so this grant reaches the card
  # vault's own credential and nothing else in the compartment. Written
  # pre-normalised (no spaces around `=`) because the OCI API rewrites
  # statement text server-side and a spaced form produces a permanent diff.
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # Grant 3 - crypto operations on the locker's own key. OPT-IN, DEFAULT OFF.
  #
  # AWS attaches a locker_kms policy granting the instance role KMS crypto ops.
  # Whether the OCI equivalent is needed depends on something outside this
  # repository and currently unanswered (check sheet open question 9.5): the
  # hyperswitch-card-vault binary compiles only the `kms-aws` and
  # `kms-hashicorp-vault` features - there is no `kms-gcp`, and by extension no
  # reason to assume a `kms-oci`. If the application cannot speak to OCI KMS,
  # granting it access is permission with no purpose, which is exactly the kind
  # of grant this port is supposed to be removing.
  #
  # So it is off until someone confirms the application can use it. Turning it
  # on is a one-line `values` change.
  #
  # UNVERIFIED in this session: the exact condition variable for per-key
  # scoping. `target.key.id` is the form used for other resource types and is
  # the expected spelling, but it was not confirmed against Oracle's KMS policy
  # reference here. Confirm before enabling; an invalid condition variable is
  # accepted by the API and silently matches nothing, which fails CLOSED (the
  # safe direction) but looks like a broken application.
  # ---------------------------------------------------------------------------
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
