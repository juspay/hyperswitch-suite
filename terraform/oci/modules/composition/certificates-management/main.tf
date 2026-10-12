# =============================================================================
# OCI Certificates Management - the AWS ACM analogue
#
# Strategy: DIRECT-RESOURCE. `search_modules` for "oci certificate" returns
# zero results - not a stale or unverified module, none at all - so there is
# nothing to wrap. This mirrors what the GCP port already found for
# certificate-manager ("No registry module covers it, so this wraps the raw
# resources") and inverts the AWS habit, where composition/acm is a pass-through
# to terraform-aws-modules/acm/aws v6.3.0.
#
# THE HEADLINE DIVERGENCE, stated once, here, at the top:
#
#   OCI CANNOT ISSUE A PUBLICLY-TRUSTED CERTIFICATE.
#
# `oci_certificates_management_certificate.certificate_config.config_type`
# accepts exactly three values - ISSUED_BY_INTERNAL_CA,
# MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA, IMPORTED - verified against the
# oracle/oci v9 provider schema, not from memory. There is no fourth
# "publicly issued" option anywhere in the schema. ACM's headline behaviour
# (ask for a certificate, prove domain ownership with a DNS record, receive a
# browser-trusted certificate for free, and have it renewed forever with no
# further action) has NO equivalent on this cloud.
#
# acm.md verdicts encoded below:
#   feature 1 public issuance ............ NONE  - no resource can express it
#   feature 2 DNS-01 validation .......... NONE  - nothing to validate against
#   feature 7 CT-logging control ......... NONE  - meaningless without a public CA
#   feature 4 automatic renewal .......... PARTIAL - CA-issued only, see below
#   feature 9 export to non-LB compute ... PARTIAL - Certificates Runtime API,
#                                          outside the management-plane
#                                          resources this module owns
#   feature 10 wait_for_validation ....... SUBSTITUTE - generic `timeouts`
#
# What a real public certificate costs on OCI: an externally-run ACME client
# (or a purchased certificate), IMPORTED here, and a self-managed renewal
# automation with a hard-TLS-outage failure mode. That automation is NOT in
# this module and cannot be - it is a scheduled job, not a Terraform resource.
# The `self_managed_renewal` output exists so an alarm can be built against it.
# =============================================================================

# -----------------------------------------------------------------------------
# Root certificate authority (optional)
# -----------------------------------------------------------------------------
# See variables.tf: this is new surface with no AWS or GCP counterpart, and
# whether it belongs here or in a shared platform-CA unit is acm.md oracle-gate
# item 2, unconsulted. Default is off, so the shape is not decided by silence.
resource "oci_certificates_management_certificate_authority" "root" {
  count = var.create_root_ca ? 1 : 0

  compartment_id = var.compartment_id
  name           = coalesce(var.root_ca_name, "${local.name_prefix}-root-ca")
  description    = "Private root CA for ${local.name_prefix}. NOT publicly trusted - every client must be configured to trust it explicitly."

  # No Oracle-managed-key shortcut exists: the CA's private key must live in a
  # Vault key the caller supplies. A prerequisite the AWS module never had.
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

  # Constraints ACM does not expose at all. Emitted only when asked for, so an
  # unset variable leaves Oracle's own default rather than a guess of ours.
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
# Certificates
# -----------------------------------------------------------------------------
# One resource, three issuance paths, selected per entry. for_each over the map
# mirrors the AWS module's own for_each shape so the two read side by side.
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

    # --- CA-issued path -----------------------------------------------------
    # Every one of these is ignored by the provider on the IMPORTED path, so
    # they are nulled out explicitly rather than left to chance.
    issuer_certificate_authority_id = each.value.config_type == "IMPORTED" ? null : coalesce(
      each.value.issuer_certificate_authority_id,
      local.root_ca_id
    )
    certificate_profile_type = each.value.config_type == "IMPORTED" ? null : each.value.certificate_profile_type
    key_algorithm            = each.value.config_type == "IMPORTED" ? null : each.value.key_algorithm
    signature_algorithm      = each.value.config_type == "IMPORTED" ? null : each.value.signature_algorithm
    csr_pem                  = each.value.config_type == "MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA" ? each.value.csr_pem : null

    # --- IMPORTED path ------------------------------------------------------
    # The only route to a browser-trusted certificate on OCI. The PEM was
    # produced by an ACME client or bought from a public CA; nothing in this
    # module obtained it and nothing in this module renews it.
    certificate_pem            = each.value.config_type == "IMPORTED" ? each.value.certificate_pem : null
    cert_chain_pem             = each.value.config_type == "IMPORTED" ? each.value.cert_chain_pem : null
    private_key_pem            = each.value.config_type == "IMPORTED" ? each.value.private_key_pem : null
    private_key_pem_passphrase = each.value.config_type == "IMPORTED" ? each.value.private_key_pem_passphrase : null

    # subject is a CA-issuance instruction ("issue a cert for this name"), not
    # a description of an existing one - an imported certificate already
    # carries its own subject inside the PEM, so the block must be absent.
    dynamic "subject" {
      for_each = each.value.config_type == "ISSUED_BY_INTERNAL_CA" ? [1] : []

      content {
        common_name = each.value.common_name
      }
    }

    # acm.md feature 3, FULL. SANs are generic X.509 and survive the port
    # unchanged - but only on the CA-issued path, because an imported PEM's
    # SANs are whatever the external issuer put in it and are not restatable
    # here. Wildcards are legal; a wildcard private-CA cert is still not
    # publicly trusted.
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

  # --- acm.md feature 4, PARTIAL --------------------------------------------
  # Genuine Oracle-managed renewal, but ONLY where Oracle is the issuer. On an
  # IMPORTED certificate there is no issuer relationship to renew against and
  # the schema exposes no rotation hook, so this block is unreachable there -
  # variables.tf rejects the combination outright rather than letting an
  # operator believe renewal is covered when it is not.
  dynamic "certificate_rules" {
    for_each = (each.value.config_type != "IMPORTED" && each.value.renewal_interval != null) ? [1] : []

    content {
      rule_type              = "CERTIFICATE_RENEWAL_RULE"
      renewal_interval       = each.value.renewal_interval
      advance_renewal_period = coalesce(each.value.advance_renewal_period, "P7D")
    }
  }

  # --- acm.md feature 10, SUBSTITUTE ----------------------------------------
  # AWS has purpose-built wait_for_validation / validation_timeout /
  # validation_allow_overwrite_records, because DNS validation is a real
  # apply-time wait. OCI has no validation step, so the only lifecycle control
  # is Terraform's own generic timeouts block. Different mechanism, comparable
  # practical effect (apply blocks until ready or gives up).
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
