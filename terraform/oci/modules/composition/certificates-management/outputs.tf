###############################################################################
# Output contract
#
# The AWS module's output names are kept wherever the semantics survive
# (skill section 6.9). OCIDs replace ARNs, so `certificate_arns` becomes
# `certificate_ids` - the single value composition/load-balancer's OCI port
# consumes for oci_load_balancer_listener.ssl_configuration.certificate_ids,
# a one-for-one replacement of the ACM-ARN-into-certificate_arn handoff.
#
# Deliberately ABSENT, each a recorded gap rather than a silent drop:
#   - certificate_domain_validation_options: there is no domain validation on
#     OCI. A private-CA certificate needs no proof of domain ownership, and an
#     IMPORTED certificate's proof (if any) happened in an external ACME client
#     before Terraform ever saw the PEM. acm.md feature 2, NONE.
#   - validation_route53_record_fqdns: same reason. Nothing to publish, and
#     therefore no coupling to the `dns` module at all - a real structural
#     simplification versus the GCP precedent, where certificate-manager must
#     hand dns_authorization_records to cloud-dns.
#   - distinct_domain_names: AWS derives it from domain_name +
#     subject_alternative_names, both of which exist only on the CA-issued
#     path here; an IMPORTED certificate's names live inside the PEM and are
#     not readable from the management-plane resource. Emitting a map that is
#     silently empty for exactly the certificates that matter most would be
#     worse than not emitting it.
###############################################################################

output "certificate_ids" {
  description = "Map of logical certificate name to OCID. Replaces AWS's certificate_arns. This is what load-balancer's ssl_configuration.certificate_ids consumes."
  value       = { for k, c in oci_certificates_management_certificate.this : k => c.id }
}

output "certificates" {
  description = "Full detail map, mirroring the AWS output of the same name as closely as the OCI schema allows: id, name, config_type, trust_domain, issuer CA, current version number and lifecycle state."
  value = {
    for k, c in oci_certificates_management_certificate.this : k => {
      id                              = c.id
      name                            = c.name
      compartment_id                  = c.compartment_id
      config_type                     = var.certificates[k].config_type
      trust_domain                    = var.certificates[k].trust_domain
      issuer_certificate_authority_id = c.issuer_certificate_authority_id
      current_version_number          = c.current_version_number
      state                           = c.state
      # true only when the PEM came from a publicly-trusted issuer outside OCI.
      # Never true for anything Oracle issued - see main.tf's header.
      publicly_trusted = var.certificates[k].trust_domain == "public"
    }
  }
}

output "certificate_statuses" {
  description = "Map of logical certificate name to lifecycle state. Same name as the AWS output; the value vocabulary is OCI's (ACTIVE, CREATING, FAILED, ...) rather than ACM's (ISSUED, PENDING_VALIDATION, ...) because there is no validation phase to be pending on."
  value       = { for k, c in oci_certificates_management_certificate.this : k => c.state }
}

output "certificate_authority_id" {
  description = "OCID of the root CA this module created, or the shared CA it was pointed at, or null when neither. No AWS counterpart - the AWS module only ever references a CA (private_authority_arn), it never owns one."
  value       = local.root_ca_id
}

output "certificate_authority_ids" {
  description = "Map of CA name to OCID for every CA this module created. A map rather than a scalar so a future subordinate-CA hierarchy is an additive change, not a breaking one."
  value       = { for ca in oci_certificates_management_certificate_authority.root : ca.name => ca.id }
}

output "self_managed_renewal" {
  description = <<-EOT
    Logical names of the certificates NOBODY renews automatically - every
    IMPORTED certificate, i.e. exactly the ones that are publicly trusted and
    therefore exactly the ones whose expiry is a hard TLS outage rather than a
    warning banner (acm.md gap on feature 4).

    This output exists to be consumed, not read: point an expiry alarm at it
    from day one. On AWS this list would always be empty, because ACM renewed
    everything invisibly. On OCI it is the operational debt the port creates.
  EOT
  value       = sort(keys(local.imported_certificates))
}

output "oracle_managed_renewal" {
  description = "Logical names of the certificates Oracle renews itself (CA-issued with a certificate_rules block). The complement of self_managed_renewal, minus any CA-issued certificate that was given no renewal_interval."
  value = sort([
    for k, c in local.ca_issued_certificates : k if c.renewal_interval != null
  ])
}
