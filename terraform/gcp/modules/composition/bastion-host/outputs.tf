output "instance_name" {
  description = "Name of the bastion instance"
  value       = module.bastion_host.hostname
}

output "instance_self_link" {
  description = "Self-link of the bastion instance"
  value       = module.bastion_host.self_link
}

output "service_account_email" {
  description = "Email of the bastion's service account"
  value       = module.bastion_host.service_account
}

output "session_log_bucket_name" {
  description = "Name of the session log bucket, if enabled"
  value       = var.enable_session_logging ? module.session_log_bucket[0].name : null
}

# ==============================================================================
# Tunnel targets
# ==============================================================================
output "connection_targets" {
  description = "Resolved host/port of every data store reachable through this bastion, keyed by short name - the machine-readable counterpart of tunnel_commands"
  value = {
    for k, t in var.connection_targets : k => {
      host        = t.host
      port        = t.port
      local_port  = coalesce(t.local_port, t.port)
      description = t.description
    }
  }
}

# A ready-to-paste command per target. `-N` means "no remote command" - the
# session exists only to carry the forward - so each of these blocks in the
# foreground and is torn down with Ctrl-C.
#
# Note for AlloyDB specifically: the instance is sslMode=ENCRYPTED_ONLY, so the
# psql on the far end of the forward must ask for TLS (`sslmode=require`). It
# does not need to verify a server certificate, so no CA bundle has to be moved
# around - but a bare `psql -h 127.0.0.1` with no sslmode will be refused by the
# server, which reads as "the tunnel is broken" when it is not.
output "tunnel_commands" {
  description = "Ready-to-run `gcloud compute ssh --tunnel-through-iap` local-port-forward command for each connection_targets entry"
  value = {
    for k, t in var.connection_targets :
    k => join(" ", [
      "gcloud compute ssh ${local.instance_name}",
      "--project=${var.project_id}",
      "--zone=${var.zone}",
      "--tunnel-through-iap",
      "-- -N -L ${coalesce(t.local_port, t.port)}:${t.host}:${t.port}",
    ])
  }
}
