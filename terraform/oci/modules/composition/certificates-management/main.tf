# OCI Certificates Management - the AWS ACM analogue
#
# OCI CANNOT ISSUE A PUBLICLY-TRUSTED CERTIFICATE. config_type accepts only
# ISSUED_BY_INTERNAL_CA, MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA and IMPORTED.
# A publicly-trusted cert must be IMPORTED from an ACME client or a purchased CA,
# with self-managed renewal.

# -----------------------------------------------------------------------------
# Root certificate authority (optional)
# -----------------------------------------------------------------------------
resource "oci_certificates_management_certificate_authority" "root" {
  count = var.create_root_ca ? 1 : 0

  compartment_id = var.compartment_id
  name           = coalesce(var.root_ca_name, "${local.name_prefix}-root-ca")
  description    = "Private root CA for ${local.name_prefix}. NOT publicly trusted - every client must be configured to trust it explicitly."

  # The CA's private key must live in a Vault key the caller supplies - no Oracle-managed option.
  kms_key_id = var.root_ca_kms_key_id

  certificate_authority_config {
    config_type       = "ROOT_CA_GENERATED_INTERNALLY"
    signing_algorithm = var.root_ca_signing_algorithm
    version_name      = "${local.name_prefix}-root-ca-v1"

    subject {
      common_name = var.root_ca_common_name
    }

    validity {
      time_of_validity_not_after = var.root_ca_validity_not_after
    }
  }

  # Emitted only when asked for, so an unset variable leaves Oracle's default.
  dynamic "certificate_authority_rules" {
    for_each = (var.root_ca_max_validity_duration != null || var.root_ca_path_length_constraint != null) ? [1] : []

    content {
      rule_type                                   = "CERTIFICATE_AUTHORITY_ISSUANCE_EXPIRY_RULE"
      leaf_certificate_max_validity_duration      = var.root_ca_max_validity_duration
      certificate_authority_max_validity_duration = var.root_ca_max_validity_duration
    }
  }

  dynamic "certificate_revocation_list_details" {
    for_each = var.root_ca_crl_object_storage != null ? [var.root_ca_crl_object_storage] : []

    content {
      custom_formatted_urls = certificate_revocation_list_details.value.custom_formatted_urls

      object_storage_config {
        object_storage_bucket_name        = certificate_revocation_list_details.value.bucket_name
        object_storage_namespace          = certificate_revocation_list_details.value.namespace
        object_storage_object_name_format = certificate_revocation_list_details.value.object_name_format
      }
    }
  }

  freeform_tags = merge(local.common_freeform_tags, { "component" = "certificates-management" })

  lifecycle {
    precondition {
      condition     = var.root_ca_common_name != null && var.root_ca_kms_key_id != null && var.root_ca_validity_not_after != null
      error_message = "create_root_ca = true requires root_ca_common_name, root_ca_kms_key_id (a Vault asymmetric key - there is no Oracle-managed-key option) and root_ca_validity_not_after."
    }

    precondition {
      condition     = var.default_issuer_ca_id == null
      error_message = "create_root_ca and default_issuer_ca_id are mutually exclusive: either this module owns the CA or it references a shared one."
    }
  }
}

# -----------------------------------------------------------------------------
# Certificates - one resource, three issuance paths, selected per entry
# -----------------------------------------------------------------------------
resource "oci_certificates_management_certificate" "this" {
  for_each = var.certificates

  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-${each.key}"
  description = coalesce(
    each.value.description,
    "${each.key} certificate for ${local.name_prefix} (${each.value.trust_domain} trust domain, ${each.value.config_type})"
  )

  certificate_config {
    config_type  = each.value.config_type
    version_name = each.value.version_name

    # CA-issued path: these are ignored by the provider on the IMPORTED path, so nulled explicitly.
    issuer_certificate_authority_id = each.value.config_type == "IMPORTED" ? null : coalesce(
      each.value.issuer_certificate_authority_id,
      local.root_ca_id
    )
    certificate_profile_type = each.value.config_type == "IMPORTED" ? null : each.value.certificate_profile_type
    key_algorithm            = each.value.config_type == "IMPORTED" ? null : each.value.key_algorithm
    signature_algorithm      = each.value.config_type == "IMPORTED" ? null : each.value.signature_algorithm
    csr_pem                  = each.value.config_type == "MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA" ? each.value.csr_pem : null

    # IMPORTED path - the only route to a browser-trusted cert; nothing here renews it.
    certificate_pem            = each.value.config_type == "IMPORTED" ? each.value.certificate_pem : null
    cert_chain_pem             = each.value.config_type == "IMPORTED" ? each.value.cert_chain_pem : null
    private_key_pem            = each.value.config_type == "IMPORTED" ? each.value.private_key_pem : null
    private_key_pem_passphrase = each.value.config_type == "IMPORTED" ? each.value.private_key_pem_passphrase : null

    # subject is a CA-issuance instruction; an imported cert already carries its own inside the PEM.
    dynamic "subject" {
      for_each = each.value.config_type == "ISSUED_BY_INTERNAL_CA" ? [1] : []

      content {
        common_name = each.value.common_name
      }
    }

    # SANs only on the CA-issued path - an imported PEM's SANs are not restatable here.
    dynamic "subject_alternative_names" {
      for_each = each.value.config_type == "ISSUED_BY_INTERNAL_CA" ? each.value.subject_alternative_names : []

      content {
        type  = subject_alternative_names.value.type
        value = subject_alternative_names.value.value
      }
    }

    dynamic "validity" {
      for_each = (each.value.config_type == "ISSUED_BY_INTERNAL_CA" && each.value.validity_not_after != null) ? [1] : []

      content {
        time_of_validity_not_after  = each.value.validity_not_after
        time_of_validity_not_before = each.value.validity_not_before
      }
    }
  }

  # Oracle-managed renewal only where Oracle is the issuer; variables.tf blocks it on IMPORTED.
  dynamic "certificate_rules" {
    for_each = (each.value.config_type != "IMPORTED" && each.value.renewal_interval != null) ? [1] : []

    content {
      rule_type              = "CERTIFICATE_RENEWAL_RULE"
      renewal_interval       = each.value.renewal_interval
      advance_renewal_period = coalesce(each.value.advance_renewal_period, "P7D")
    }
  }

  # OCI has no validation step; generic timeouts are the only lifecycle control.
  timeouts {
    create = var.certificate_create_timeout
    update = var.certificate_create_timeout
  }

  freeform_tags = merge(
    local.common_freeform_tags,
    {
      "component"    = "certificates-management"
      "certificate"  = each.key
      "trust_domain" = each.value.trust_domain
      # Deliberately queryable: "which certificates will nobody renew for us?"
      "renewal" = each.value.config_type == "IMPORTED" ? "self-managed" : "oracle-managed"
    }
  )

  lifecycle {
    precondition {
      condition     = each.value.config_type == "IMPORTED" || coalesce(each.value.issuer_certificate_authority_id, local.root_ca_id, "unset") != "unset"
      error_message = "Certificate '${each.key}' is CA-issued but no issuer is available: set its issuer_certificate_authority_id, or set default_issuer_ca_id, or create_root_ca = true."
    }
  }
}
