# -----------------------------------------------------------------------------
# Naming, tags, and a statement renderer that renders nothing by default.
#
# The renderer is present and is the same character-for-character copy of
# `oke-workload-identity/locals.tf` the rest of this wave uses, so that a grant
# added later goes through the same normalisation and the same four hard-coded
# `where` conditions. It is not dead code waiting for a rewrite; it is the same
# code, exercised with an empty grant list.
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}-ratelimiter"

  common_freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "ratelimiter"
      managed_by  = "terraform"
    },
    var.region != null ? { region = var.region } : {},
    var.freeform_tags
  )

  # No base grants. See variables.tf header point 2: the AWS identity attaches
  # no policy in any of the six live roots, and on OCI an identity with no
  # grants is no statements.
  all_grants = [
    for g in var.additional_grants : {
      verb           = g.verb
      resource_type  = g.resource_type
      compartment_id = coalesce(g.compartment_id, var.compartment_id)
      condition      = g.condition
    }
  ]

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

  # Emitted even when there are no grants: the (cluster, namespace, service
  # account) tuple is the thing a future grant would be written against, and a
  # reviewer needs to see which workload this module speaks for.
  authorized_workloads = [
    for cluster_id in var.cluster_ids : {
      cluster_id      = cluster_id
      namespace       = lower(trimspace(var.k8s_namespace))
      service_account = lower(trimspace(var.k8s_service_account_name))
    }
  ]

  cache_configured = var.cache_cluster_id != null

  # TLS is hardcoded true and is NOT a reflection of configuration. OCI Cache
  # accepts TLS connections only and offers no Terraform-level off switch, which
  # is the OPPOSITE of the AWS module (transit_encryption_enabled = false in
  # every live unit) and of the GCP valkey unit. A consumer reading this must
  # not carry the AWS default across in their head: if the client cannot
  # negotiate TLS the connection is reset, it does not degrade.
  cache_connection_info = {
    primary_endpoint = var.cache_primary_endpoint_ip_address
    primary_fqdn     = var.cache_primary_fqdn
    reader_endpoint  = var.cache_replicas_endpoint_ip_address
    reader_fqdn      = var.cache_reader_fqdn
    port             = var.cache_port
    software_version = var.cache_software_version
    tls_required     = true
  }
}
