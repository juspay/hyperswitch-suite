output "zone_ids" {
  description = "Map of logical zone key to OCID. Same name and shape as the AWS output."
  value       = { for k, z in oci_dns_zone.this : k => z.id }
}

output "zone_names" {
  description = "Map of logical zone key to fully qualified zone name."
  value       = { for k, z in oci_dns_zone.this : k => z.name }
}

output "zone_ids_by_name" {
  description = "Map of fully qualified zone name to OCID. Same name and shape as the AWS output; the convenience inversion consumers that know a domain but not a logical key use."
  value       = { for k, z in oci_dns_zone.this : z.name => z.id }
}

output "name_servers" {
  description = "Map of logical zone key to the zone's authoritative nameserver hostnames. PUBLIC ZONES ONLY - private zones are served by the VCN resolver and have no delegable nameservers, so including them would hand a registrar a set of names it can do nothing with. Same reasoning applies on AWS, where the output is equally meaningless for a private hosted zone."
  value = {
    for k, z in oci_dns_zone.this : k => [for ns in z.nameservers : ns.hostname]
    if var.zones[k].type == "public"
  }
}

output "record_domains" {
  description = "Map of the flattened <zone_key>_<record_key> composite key to the fully qualified domain of the rrset. Replaces AWS's record_fqdns plus record_names, which collapse into one here."
  value       = { for k, r in oci_dns_rrset.this : k => r.domain }
}

output "private_view_id" {
  description = "OCID of the PRIVATE view holding this module's private zones - created here, or the shared one supplied via private_view_id, or null when there are no private zones. No AWS counterpart: on AWS the zone itself carries its VPC visibility."
  value       = local.private_view_id
}

output "vcn_resolver_id" {
  description = "OCID of the VCN's auto-created DNS resolver this module attached its private view to, or null when no attachment was made. Exported so a validation step or a second unit can assert the attachment happened - the failure mode when it does not is silent (resolver.tf)."
  value       = try(data.oci_core_vcn_dns_resolver_association.this[0].dns_resolver_id, null)
}

output "private_zones_resolvable_in_vcn" {
  description = "True when every private zone this module created is reachable from the VCN, i.e. a view exists AND it is attached to the VCN's resolver. False - with private zones present - means the zones applied cleanly and resolve from nowhere. Emitted as a boolean precisely because that state produces no error anywhere else."
  value       = !local.has_private_zones || local.attach_resolver
}

output "summary" {
  description = "Per-zone rollup mirroring the AWS output of the same name: id, name, type, record count, and - new on OCI - whether the zone is actually reachable from the VCN."
  value = {
    for k, z in oci_dns_zone.this : k => {
      id             = z.id
      name           = z.name
      type           = var.zones[k].type
      record_count   = length(var.zones[k].records)
      view_id        = var.zones[k].type == "private" ? local.private_view_id : null
      vcn_resolvable = var.zones[k].type == "private" ? local.attach_resolver : null
    }
  }
}
