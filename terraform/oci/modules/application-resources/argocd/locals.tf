# -----------------------------------------------------------------------------
# Grant list and statement renderer.
#
# Same divergence as every module in this wave, recorded where it lives: the
# check sheet (section 5) proposes a nested `../oke-workload-identity` call that
# owns an `oci_identity_policy` for this app. The orchestrator took the other
# branch - ONE shared policy object per environment, statements contributed by
# app modules - because a policy object per app per region root is 132 objects
# against a hard 100-per-tenancy limit. So this module renders text.
#
# The renderer is a character-for-character copy of
# `oke-workload-identity/locals.tf`, and every string it emits is re-checked at
# plan time by that module's four preconditions when the orchestrator wires it
# in. Prefer `workload_grants` over `policy_statements` where the wiring allows:
# the canonical renderer cannot forget a condition, and on OCI a forgotten
# condition fails open.
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}-argocd"

  common_freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "argocd"
      managed_by  = "terraform"
    },
    var.region != null ? { region = var.region } : {},
    var.freeform_tags
  )

  # ---------------------------------------------------------------------------
  # Grants.
  #
  # 1. `use clusters` in each deploy-target compartment - the OCI answer to
  #    "obtain credentials for the target cluster". On AWS this was implicit in
  #    the assumed cross-account role; here it is an explicit verb.
  # 2. `read objects` + `read buckets` in the artefact compartment - the
  #    substitute for AmazonS3ReadOnlyAccess, compartment-scoped rather than
  #    account-wide.
  # 3. Whatever the caller adds.
  #
  # Nothing else. In particular NOT `manage all-resources`, which is what
  # Oracle's own tutorial publishes; see variables.tf header point 2.
  # ---------------------------------------------------------------------------
  deploy_grants = [
    for c in var.target_compartment_ids : {
      verb           = var.target_cluster_verb
      resource_type  = "clusters"
      compartment_id = c
      condition      = null
    }
  ]

  artifact_grants = var.artifact_compartment_id == null ? [] : [
    for rt in var.artifact_resource_types : {
      verb           = "read"
      resource_type  = rt
      compartment_id = var.artifact_compartment_id
      condition      = null
    }
  ]

  extra_grants = [
    for g in var.additional_grants : {
      verb           = g.verb
      resource_type  = g.resource_type
      compartment_id = coalesce(g.compartment_id, var.compartment_id)
      condition      = g.condition
    }
  ]

  all_grants = concat(local.deploy_grants, local.artifact_grants, local.extra_grants)

  # ---------------------------------------------------------------------------
  # Render: one statement per (service account x cluster x grant). Enumerated,
  # because pattern values on `request.principal.*` are undocumented
  # (identity-model.md section 9 Q5) - there is no verified wildcard that would
  # collapse `argocd/*` and `argo-workflows/*`.
  # ---------------------------------------------------------------------------
  grant_tuples = flatten([
    for g in local.all_grants : [
      for sa in var.service_accounts : [
        for cluster_id in var.cluster_ids : {
          cluster_id      = cluster_id
          namespace       = lower(trimspace(sa.namespace))
          service_account = lower(trimspace(sa.name))
          verb            = lower(trimspace(g.verb))
          resource_type   = lower(trimspace(g.resource_type))
          location        = g.compartment_id
          condition       = g.condition == null ? "" : ",${trimspace(g.condition)}"
        }
      ]
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

  workload_grants = flatten([
    for g in local.all_grants : [
      for sa in var.service_accounts : {
        namespace       = lower(trimspace(sa.namespace))
        service_account = lower(trimspace(sa.name))
        verb            = lower(trimspace(g.verb))
        resource_type   = lower(trimspace(g.resource_type))
        compartment_id  = g.compartment_id
        condition       = g.condition
      }
    ]
  ])

  authorized_workloads = flatten([
    for sa in var.service_accounts : [
      for cluster_id in var.cluster_ids : {
        cluster_id      = cluster_id
        namespace       = lower(trimspace(sa.namespace))
        service_account = lower(trimspace(sa.name))
      }
    ]
  ])

  # ---------------------------------------------------------------------------
  # Cross-tenancy. KEPT SEPARATE FROM policy_statements ON PURPOSE.
  #
  # `Define` and `Endorse` must be attached at the MANAGEMENT TENANCY ROOT, and
  # the matching `Define`/`Admit` at the TARGET tenancy root - "cross-tenancy
  # policies must be defined under the root compartment on both sides". The
  # shared oke-workload-identity object is attached at the ENVIRONMENT
  # compartment, which is not the root, so these statements cannot go into it.
  # Feeding them there would produce a policy the API accepts and that grants
  # nothing.
  #
  # Emitting them as a distinct output rather than creating the policy keeps
  # this module free of `oci_identity_policy` and leaves the two-root, two-state
  # wiring where it belongs: the live layer.
  # ---------------------------------------------------------------------------
  cross_tenancy_statements = sort(distinct(flatten([
    for t in var.cross_tenancy_targets : concat(
      ["define tenancy ${t.alias} as ${t.tenancy_ocid}"],
      flatten([
        for sa in var.service_accounts : [
          for cluster_id in var.cluster_ids : join("", [
            "endorse any-user to ${lower(var.target_cluster_verb)} clusters in tenancy ${t.alias} where all {",
            "request.principal.type='workload',",
            "request.principal.namespace='${lower(trimspace(sa.namespace))}',",
            "request.principal.service_account='${lower(trimspace(sa.name))}',",
            "request.principal.cluster_id='${cluster_id}'",
            "}",
          ])
        ]
      ])
    )
  ])))

  # Workload mappings are only meaningful for targets outside the environment
  # compartment. Same-compartment targets are already reachable.
  out_of_subtree_targets = [for c in var.target_compartment_ids : c if c != var.compartment_id]

  workload_mapping_keys = var.create_workload_mappings ? {
    for pair in flatten([
      for cluster_id in var.cluster_ids : [
        for ns in distinct([for sa in var.service_accounts : sa.namespace]) : [
          for target in local.out_of_subtree_targets : {
            key        = "${cluster_id}|${ns}|${target}"
            cluster_id = cluster_id
            namespace  = ns
            target     = target
          }
        ]
      ]
    ]) : pair.key => pair
  } : {}
}
