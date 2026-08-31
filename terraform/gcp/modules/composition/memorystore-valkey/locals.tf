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

  # module.valkey_cluster.psc_auto_connection (the submodule's own output)
  # is confusingly shaped - it's endpoints[0].connections[0], a wrapper
  # object that ITSELF has a field also named psc_auto_connection (a
  # 1-element list) - not the connection details directly. Derive straight
  # from the raw `endpoints` output instead, filtering for the actual
  # discovery-type connection rather than assuming index [0] is always it
  # (confirmed against a real applied instance 2026-08-28: index [0] here
  # happened to be correct, but connection_type is the real signal, not
  # position).
  discovery_connections = flatten([
    for e in module.valkey_cluster.endpoints : [
      for c in e.connections : c.psc_auto_connection[0]
      if length(c.psc_auto_connection) > 0 && c.psc_auto_connection[0].connection_type == "CONNECTION_TYPE_DISCOVERY"
    ]
  ])
  discovery_connection = try(local.discovery_connections[0], null)
}
