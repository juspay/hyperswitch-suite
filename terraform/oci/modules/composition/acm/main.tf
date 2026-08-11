# ============================================================================
# OCI Certificates Management - equivalent of the AWS `acm` composition
# module (which wraps terraform-aws-modules/acm/aws). No verified registry
# module exists for OCI Certificates Management - raw oci provider resource.
# ============================================================================
resource "oci_certificates_management_certificate" "this" {
  for_each = var.certificates

  compartment_id = var.compartment_id
  name           = "${var.environment}-${var.project_name}-${each.key}-cert"

  certificate_config {
    config_type = each.value.imported_certificate_pem != null ? "IMPORTED" : "ISSUED_BY_INTERNAL_CA"

    # ISSUED_BY_INTERNAL_CA path (closest analog to ACM's managed
    # issue-and-renew flow, using an OCI Certificate Authority you manage)
    issuer_certificate_authority_id = each.value.imported_certificate_pem == null ? each.value.certificate_authority_id : null
    key_algorithm                   = each.value.imported_certificate_pem == null ? each.value.key_algorithm : null

    dynamic "subject" {
      for_each = each.value.imported_certificate_pem == null ? [1] : []
      content {
        common_name = each.value.common_name
      }
    }

    dynamic "subject_alternative_names" {
      for_each = each.value.imported_certificate_pem == null ? each.value.subject_alternative_names : []
      content {
        type  = "DNS"
        value = subject_alternative_names.value
      }
    }

    dynamic "validity" {
      for_each = each.value.validity_not_after != null ? [1] : []
      content {
        time_of_validity_not_after = each.value.validity_not_after
      }
    }

    # IMPORTED path (closest analog to ACM's "import a certificate" flow)
    certificate_pem = each.value.imported_certificate_pem
    cert_chain_pem  = each.value.imported_cert_chain_pem
    private_key_pem = each.value.imported_private_key_pem
  }

  freeform_tags = merge(var.freeform_tags, each.value.tags)
  defined_tags  = var.defined_tags
}
