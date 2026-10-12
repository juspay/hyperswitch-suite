# Grant list and statement renderer. ONE shared policy object per environment,
# with app modules contributing statements - a per-app policy object is
# unbuildable at a 100-object tenancy limit. Renderer is the canonical copy
# from oke-workload-identity; its four plan-time preconditions re-check every
# string this module emits.

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

  # Grants: use clusters in each deploy-target compartment (kubeconfig), read
  # objects/buckets in the artefact compartment (S3-read substitute), plus
  # caller-added. NOT `manage all-resources` - Oracle's tutorial shorthand that
  # hands ArgoCD full compartment control.
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

  # Render: one statement per (service account x cluster x grant). Enumerated -
  # no verified wildcard on request.principal.*.
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

  # Cross-tenancy Define/Endorse. KEPT SEPARATE FROM policy_statements: these
  # must attach at the MANAGEMENT TENANCY ROOT (and Define/Admit at the target
  # tenancy root), which the environment-compartment shared object cannot carry.
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
