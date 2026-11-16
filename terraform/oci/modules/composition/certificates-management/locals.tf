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

  # ---------------------------------------------------------------------------
  # Which certificates take which issuance path.
  #
  # OCI has exactly three config_type values and NONE of them is "publicly
  # trusted, issued by Oracle" (acm.md features 1/2/7, verdict NONE). So the
  # map is split here, once, and every downstream decision reads the split
  # rather than re-deriving it:
  #
  #   ca_issued  - ISSUED_BY_INTERNAL_CA / MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA
  #                Oracle owns the issuer, so certificate_rules give real
  #                automatic renewal. NOT publicly trusted.
  #   imported   - IMPORTED. PEM obtained elsewhere (ACME / purchased CA).
  #                Publicly trusted if and only if the PEM is. NO renewal
  #                mechanism exists at all - see the self_managed_renewal
  #                output and acm.md gap 4 (feature 4).
  # ---------------------------------------------------------------------------
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
