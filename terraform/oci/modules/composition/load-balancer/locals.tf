locals {
  name_prefix = "${var.project_name}-${var.environment}"

  display_name = coalesce(
    var.display_name,
    var.name != null ? "${local.name_prefix}-${var.name}" : "${local.name_prefix}-lb"
  )

  common_freeform_tags = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "managed_by"  = "terraform"
    },
    var.freeform_tags
  )

  # Every NSG on the load balancer: the empty one this module owns for
  # security-rules to fill, plus anything the caller already has (the OKE
  # module's public_lb_nsg_id / internal_lb_nsg_id, typically).
  network_security_group_ids = compact(concat(
    var.create_nsg ? [oci_core_network_security_group.this[0].id] : [],
    var.network_security_group_ids,
  ))

  # Backends flattened out of their backend sets, one resource per backend,
  # keyed "${backend_set}_${backend}" so two sets can hold the same host:port.
  flattened_backends = merge([
    for bs_key, bs in var.backend_sets : {
      for b_key, b in bs.backends :
      "${bs_key}_${b_key}" => merge(b, { backend_set = bs_key })
    }
  ]...)

  # Listeners that terminate TLS. Used only for the precondition below - the
  # single-certificate constraint is a real OCI limit, not a module choice.
  tls_listeners = {
    for k, l in var.listeners : k => l if l.certificate_ids != null || l.certificate_name != null
  }
}
