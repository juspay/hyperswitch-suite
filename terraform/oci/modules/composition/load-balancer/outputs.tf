# Output contract. OCIDs replace ARNs (so every *_arn output is gone) and the
# `alb_` prefix is dropped - this is an OCI load balancer, not an ALB.
# Deliberately ABSENT: alb_dns_name/alb_zone_id (the OCI LB has a real IP, not an
# AWS-hosted hostname; `ip_address` replaces them); alb_arn_suffix (no
# CloudWatch); security_group_arn (nsg_id carries the OCID); the route53_* set
# (DNS now lives in the `dns` module).

output "load_balancer_id" {
  description = "OCID of the load balancer. Replaces AWS's alb_arn and alb_id, which collapse into one value here. This is also the whole of what the WAF owner needs - oci_waf_web_app_firewall attaches with load_balancer_id + backend_type = \"LOAD_BALANCER\" (load-balancer.md feature 8)."
  value       = oci_load_balancer_load_balancer.this.id
}

output "load_balancer_name" {
  description = "Display name of the load balancer. Replaces AWS's alb_name."
  value       = oci_load_balancer_load_balancer.this.display_name
}

output "ip_address" {
  description = "The load balancer's primary IP address - public for an internet-facing one, VCN-internal for a private one. THE key output: it replaces AWS's alb_dns_name/alb_zone_id pair, and it is what the `dns` module points a plain A record at, at the zone apex if wanted, with no ALIAS pseudo-record. Stable across recreation only when reserved_ip_id is set."
  value       = try(oci_load_balancer_load_balancer.this.ip_address_details[0].ip_address, null)
}

output "ip_addresses" {
  description = "Every IP the load balancer holds. Singular ip_address above is the first; this is the full list for the dual-stack or multi-IP cases. Derived from ip_address_details rather than the resource's own ip_addresses attribute, which the provider marks deprecated."
  value       = [for d in oci_load_balancer_load_balancer.this.ip_address_details : d.ip_address]
}

output "ip_address_details" {
  description = "Full ip_address_details list - address, is_public, and whether it is a reserved IP. Exported so a validation step can assert that anything DNS points at is actually reserved rather than ephemeral."
  value       = oci_load_balancer_load_balancer.this.ip_address_details
}

output "is_private" {
  description = "Whether this load balancer is VCN-internal. Replaces nothing on AWS (the input was simply `internal`); exported so security-rules can reason about which posture to write into the NSG."
  value       = oci_load_balancer_load_balancer.this.is_private
}

output "nsg_id" {
  description = "OCID of the EMPTY network security group this module created, or null when create_nsg = false. Replaces AWS's security_group_id. catalog/units/oci/security-rules reads this and writes the rules in during the security-last stack phase - same contract as composition/database and composition/oci-cache-valkey expose."
  value       = try(oci_core_network_security_group.this[0].id, null)
}

output "network_security_group_ids" {
  description = "Every NSG attached to the load balancer - the module's own plus any externally-owned ones passed in (typically the OKE module's public_lb_nsg_id or internal_lb_nsg_id)."
  value       = local.network_security_group_ids
}

output "listener_names" {
  description = "Map of logical listener key to the listener's name on the load balancer. Replaces AWS's listener_arns and listener_ids, which collapse into one here - an OCI listener is a named sub-resource, not an independently-addressable object."
  value       = { for k, l in oci_load_balancer_listener.this : k => l.name }
}

output "listener_details" {
  description = "Per-listener rollup mirroring the AWS output of the same name: port, protocol, the backend set it forwards to, whether it terminates TLS and which rule sets are attached."
  value = {
    for k, l in oci_load_balancer_listener.this : k => {
      name                     = l.name
      port                     = l.port
      protocol                 = l.protocol
      default_backend_set_name = l.default_backend_set_name
      rule_set_names           = l.rule_set_names
      hostname_names           = l.hostname_names
      tls_terminated           = contains(keys(local.tls_listeners), k)
    }
  }
}

output "tls_listeners" {
  description = "Map of TLS-terminating listener key to which certificate route it uses - \"certificates-management\" (an OCID from the certificates-management module) or \"uploaded-pem\" (a classic oci_load_balancer_certificate). Exported because renewal is self-managed on the uploaded-PEM path with no Oracle-side safety net, and an expiry alarm needs to know which listeners are on it."
  value = {
    for k, l in local.tls_listeners : k => l.certificate_ids != null ? "certificates-management" : "uploaded-pem"
  }
}

output "backend_set_names" {
  description = "Map of backend-set key to its name on the load balancer. New relative to AWS, where target groups belonged to a different module - see variables.tf's backend_sets description for why the boundary moved."
  value       = { for k, bs in oci_load_balancer_backend_set.this : k => bs.name }
}

output "hostname_names" {
  description = "Map of hostname resource key to its name, for listeners doing host-header routing."
  value       = { for k, h in oci_load_balancer_hostname.this : k => h.name }
}

output "rule_set_names" {
  description = "Map of rule-set key to its name. The mechanism that stands in for AWS's redirect listener default action (listeners.tf)."
  value       = { for k, r in oci_load_balancer_rule_set.this : k => r.name }
}

output "certificate_names" {
  description = "Names of the classic PEM certificates uploaded directly to this load balancer. Empty when every listener uses a Certificates Management OCID instead."
  value       = sort(keys(oci_load_balancer_certificate.this))
}
