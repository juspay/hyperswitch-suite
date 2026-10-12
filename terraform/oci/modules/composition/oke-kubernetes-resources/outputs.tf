output "cluster_access_bindings" {
  description = "Names + role/clusterrole_ref of the bindings created, for consumers and the check-sheet validation."
  value = [
    for name, b in var.cluster_access_bindings : {
      name       = name
      scope_kind = b.scope_kind
      namespace  = try(b.namespace, null)
      role_kind  = b.role_ref.kind
      role_name  = b.role_ref.name
    }
  ]
}
