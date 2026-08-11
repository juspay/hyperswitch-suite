# acm (OCI) → OCI Certificates Management

OCI equivalent of `terraform/aws/modules/composition/acm`. Uses `oci_certificates_management_certificate`. No
verified registry module exists for this service - raw `oci` provider resource.

## Important difference from ACM

AWS ACM's headline feature is **free, auto-renewing public certificates validated via DNS** (`create_route53_records`
+ `validate_certificate` in the AWS module). OCI Certificates Management has **no public-CA-with-DNS-validation
flow** — certificates are either:

1. **Issued by an OCI Certificate Authority you operate** (`ISSUED_BY_INTERNAL_CA`, used by default here via
   `certificate_authority_id`) — good for internal/mTLS traffic (e.g. the envoy-proxy mTLS listener), not for a
   publicly-trusted cert your browser will accept without a custom trust store.
2. **Imported** (`IMPORTED`, used here when `imported_certificate_pem` is set) — bring a certificate issued
   elsewhere (e.g. Let's Encrypt, or a certificate purchased from a public CA) and let OCI manage/rotate it.

For public-facing certificates that need to be trusted by browsers out of the box, issue them externally (e.g.
via `cert-manager` + Let's Encrypt inside OKE, or a third-party CA) and import them here, rather than expecting
an ACM-equivalent free-DNS-validated public cert from OCI directly.
