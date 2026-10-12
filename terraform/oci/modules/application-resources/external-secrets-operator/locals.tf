# -----------------------------------------------------------------------------
# Grant list and statement renderer.
#
# DIVERGENCE FROM THE CHECK SHEET'S PROPOSED main.tf, recorded at the point of
# divergence. The sheet (section 5) proposes `module "workload_identity"` calling
# `../oke-workload-identity`, which would own an `oci_identity_policy` for this
# app. That is identity-model.md section 5 Option A - one policy object per app
# per environment. The orchestrator has since taken the other branch: ONE shared
# policy object per environment, into which app modules contribute statements,
# because one object per app per region root at the current AWS footprint is
# 12 apps x 11 roots = 132 objects against a hard 100-per-tenancy limit.
#
# So this module renders text and creates no policy. The renderer below is a
# character-for-character copy of `oke-workload-identity/locals.tf`, and every
# string it emits is re-validated at PLAN time by that module's four
# preconditions when the orchestrator wires it in. See that file's header for
# why statement text is a security boundary and not a formatting concern.
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}-eso"

  # Where the secrets live. Defaults to the environment compartment.
  secrets_compartment_id = coalesce(var.vault_compartment_id, var.compartment_id)

  common_freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "external-secrets-operator"
      managed_by  = "terraform"
    },
    var.region != null ? { region = var.region } : {},
    var.freeform_tags
  )

  # ---------------------------------------------------------------------------
  # The two grants, and why they are two.
  #
  #   secretsmanager:GetSecretValue -> read secret-bundles  (SECRET_BUNDLE_READ)
  #   secretsmanager:DescribeSecret -> read secrets         (SECRET_READ)
  #
  # `read secrets` IS NOT ENOUGH TO READ A SECRET. It returns metadata only
  # (GetSecret, ListSecrets). ESO calls both, so both are here. The tempting
  # single-line alternative, `read secret-family`, also grants `secret-versions`,
  # which the AWS inline policy does not - broader, not equivalent.
  #
  # OPEN, and it changes this list: does a caller holding `read secret-bundles`
  # also need `use keys` on the KMS key that encrypts the secret? The Vault
  # policy reference maps GetSecretBundle to SECRET_BUNDLE_READ alone and the
  # "Getting a Secret's Contents" page states no key requirement, but nothing
  # rules it out. identity-model.md section 9 Q3 / check sheet open question 1.
  # Symptom if it is needed: ESO starts cleanly and then fails EVERY
  # ExternalSecret with a permission error. Fix: add
  # { verb = "use", resource_type = "keys" } to additional_grants.
  # ---------------------------------------------------------------------------
  base_resource_types = ["secret-bundles", "secrets"]

  # Per-secret scoping is opt-in. Empty secret_ids -> compartment-wide, which is
  # the AWS behaviour (`secret:*`). There is no configuration that grants
  # nothing - that is the deliberate inversion of the GCP module's
  # scope_to_project default.
  base_grants = flatten([
    for rt in local.base_resource_types : (
      length(var.secret_ids) == 0
      ? [{
        verb           = "read"
        resource_type  = rt
        compartment_id = local.secrets_compartment_id
        condition      = null
      }]
      : [for sid in var.secret_ids : {
        verb           = "read"
        resource_type  = rt
        compartment_id = local.secrets_compartment_id
        condition      = "target.secret.id='${sid}'"
      }]
    )
  ])

  all_grants = concat(local.base_grants, [
    for g in var.additional_grants : {
      verb           = g.verb
      resource_type  = g.resource_type
      compartment_id = coalesce(g.compartment_id, var.compartment_id)
      condition      = g.condition
    }
  ])

  # ---------------------------------------------------------------------------
  # Render: one statement per (grant x cluster). One namespace, one service
  # account - flattened to scalars because the live layer has only ever used one
  # pair.
  # ---------------------------------------------------------------------------
  grant_tuples = flatten([
    for g in local.all_grants : [
      for cluster_id in var.cluster_ids : {
        cluster_id      = cluster_id
        namespace       = lower(trimspace(var.k8s_namespace))
        service_account = lower(trimspace(var.k8s_service_account_name))
        verb            = lower(trimspace(g.verb))
        resource_type   = lower(trimspace(g.resource_type))
        location        = g.compartment_id
        condition       = g.condition == null ? "" : ",${trimspace(g.condition)}"
      }
    ]
  ])

  rendered_statements = [
    for t in local.grant_tuples : join("", [
      "allow any-user to ${t.verb} ${t.resource_type} in compartment id ${t.location} where all {",
      "request.principal.type='workload',",
      "request.principal.namespace='${t.namespace}',",
      "request.principal.service_account='${t.service_account}',",
      "request.principal.cluster_id='${t.cluster_id}'",
      t.condition,
      "}",
    ])
  ]

  # Four normalisation rules, identical to oke-workload-identity/locals.tf: the
  # OCI API rewrites statement text server-side, so anything not already in
  # normal form is a perpetual diff (oracle/terraform-provider-oci#371).
  policy_statements = sort(distinct([
    for s in concat(local.rendered_statements, var.shared_statements, var.extra_statements) :
    replace(
      replace(
        replace(
          replace(trimspace(s), "/\\s+/", " "),
        "/\\s*(!?=)\\s*/", "$1"),
      "/,\\s+/", ","),
    "/\\{\\s+|\\s+\\}/", "")
  ]))

  # The structured form of the same grants, for callers wiring
  # `oke-workload-identity.workload_grants` instead of `.statements`. Preferred:
  # the canonical renderer cannot forget a condition.
  workload_grants = [
    for g in local.all_grants : {
      namespace       = lower(trimspace(var.k8s_namespace))
      service_account = lower(trimspace(var.k8s_service_account_name))
      verb            = lower(trimspace(g.verb))
      resource_type   = lower(trimspace(g.resource_type))
      compartment_id  = g.compartment_id
      condition       = g.condition
    }
  ]

  authorized_workloads = [
    for cluster_id in var.cluster_ids : {
      cluster_id      = cluster_id
      namespace       = lower(trimspace(var.k8s_namespace))
      service_account = lower(trimspace(var.k8s_service_account_name))
    }
  ]
}
