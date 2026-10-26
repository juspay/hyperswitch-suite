locals {
  name_prefix = "${var.environment}-${var.project_name}-valkey"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "cache"
      "engine"      = "valkey"
      "managed_by"  = "terraform"
    },
    var.labels
  )

  instance_id = var.instance_id != null ? var.instance_id : "${local.name_prefix}-${var.region}"

  # Derived from the raw `endpoints` output rather than the submodule's
  # psc_auto_connection, which returns a wrapper object rather than the
  # connection details. Filter on connection_type instead of assuming a
  # position in the list.
  discovery_connections = flatten([
    for e in module.valkey_cluster.endpoints : [
      for c in e.connections : c.psc_auto_connection[0]
      if length(c.psc_auto_connection) > 0 && c.psc_auto_connection[0].connection_type == "CONNECTION_TYPE_DISCOVERY"
    ]
  ])
  discovery_connection = try(local.discovery_connections[0], null)
}
