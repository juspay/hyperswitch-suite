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
      # true only when the PEM came from a publicly-trusted issuer outside OCI; never for Oracle-issued.
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
