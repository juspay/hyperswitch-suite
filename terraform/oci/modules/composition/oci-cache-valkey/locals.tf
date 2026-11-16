locals {
  name_prefix = "${var.environment}-${var.project_name}-valkey"

  # name_suffix keeps this module non-singleton: the shared payments cache and
  # ratelimiter's own dedicated instance can both exist in one compartment.
  display_name = coalesce(
    var.display_name,
    join("-", compact([local.name_prefix, var.name_suffix]))
  )

  common_freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "cache"
      engine      = "valkey"
      managed_by  = "terraform"
    },
    var.region != null ? { region = var.region } : {},
    var.freeform_tags
  )

  is_sharded = var.cluster_mode == "SHARDED"

  # Module-owned NSG (if created) plus any additional pre-existing ones.
  # Mirrors the `database` module's identical local. Added during assembly
  # 2026-09-03 - see variables.tf create_nsg / vcn_id.
  nsg_ids = compact(concat(
    var.create_nsg ? [oci_core_network_security_group.this[0].id] : [],
    var.nsg_ids
  ))

  # Effective config set: module-created wins over a pre-existing OCID, and
  # both being set is rejected by a precondition rather than silently ordered.
  config_set_id = var.create_config_set ? one(oci_redis_oci_cache_config_set.main[*].id) : var.oci_cache_config_set_id

  # OCI Cache serves on 6379 and does not expose a port argument or attribute -
  # unlike AWS, where port is both settable and exported. Published here as a
  # constant so consumers keep a `port` in the connection contract rather than
  # each hardcoding it. Matches the AWS units' port = 6379.
  port = 6379

  # Only sharded clusters get a discovery endpoint; on a non-sharded cluster
  # the attribute comes back empty rather than absent, so normalize to null.
  discovery_ip   = local.is_sharded ? try(oci_redis_redis_cluster.main.discovery_endpoint_ip_address, null) : null
  discovery_fqdn = local.is_sharded ? try(oci_redis_redis_cluster.main.discovery_fqdn, null) : null
}
