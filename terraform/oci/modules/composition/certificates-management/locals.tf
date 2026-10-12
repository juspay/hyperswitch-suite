locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_freeform_tags = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "managed_by"  = "terraform"
    },
    var.freeform_tags
  )

  # ca_issued: ISSUED_BY_INTERNAL_CA / MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA
  #            Oracle renewal. NOT publicly trusted.
  # imported:  IMPORTED. Publicly trusted iff the PEM is. NO renewal mechanism.
  ca_issued_certificates = {
    for k, c in var.certificates : k => c
    if c.config_type != "IMPORTED"
  }

  imported_certificates = {
    for k, c in var.certificates : k => c
    if c.config_type == "IMPORTED"
  }

  # The root CA every ISSUED_BY_INTERNAL_CA certificate chains to, unless the
  # certificate names its own issuer explicitly. Either this module created it
  # (create_root_ca) or the platform supplied one (default_issuer_ca_id).
  root_ca_id = var.create_root_ca ? oci_certificates_management_certificate_authority.root[0].id : var.default_issuer_ca_id
}
