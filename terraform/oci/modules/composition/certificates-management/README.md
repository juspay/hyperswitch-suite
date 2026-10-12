# certificates-management

OCI Certificates Management: certificate authorities and certificates.

## Read this before using the module

**OCI cannot issue a publicly-trusted certificate.** `config_type` accepts only
`ISSUED_BY_INTERNAL_CA`, `MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA` and
`IMPORTED`. There is no public, DNS-validated, auto-renewing issuance path.

| Path | Publicly trusted? | Renewal |
|---|---|---|
| `ISSUED_BY_INTERNAL_CA` | no | Oracle-managed via `certificate_rules` |
| `MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA` | no | Oracle-managed |
| `IMPORTED` | only if the PEM already is | none — self-managed |

Anything an external merchant, browser or mobile SDK connects to must be
`IMPORTED` from an ACME client or a purchased certificate, with an expiry alarm
built against the `self_managed_renewal` output. Setting `trust_domain =
"public"` on a CA-issued certificate is rejected at plan time.

## Structural notes

- **No dependency on the `dns` module** — there is no ownership proof to
  publish.
- **It can own a root CA.** Off by default (`create_root_ca = false`).
- **A Vault key is a hard prerequisite for any CA.**
  `oci_certificates_management_certificate_authority.kms_key_id` is required;
  there is no Oracle-managed-key option.