output "certificate_ids" {
  value = { for k, v in oci_certificates_management_certificate.this : k => v.id }
}
