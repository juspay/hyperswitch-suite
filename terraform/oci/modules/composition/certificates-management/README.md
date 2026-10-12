# certificates-management

OCI port of `terraform/aws/modules/composition/acm`. GCP sibling:
`terraform/gcp/modules/composition/certificate-manager`.

Check sheet: `docs/multi-cloud-parity/oci/modules/acm.md` (hyperswitch-infra).
Strategy: DIRECT-RESOURCE - no registry module for this service exists.

## Read this before using the module

**OCI cannot issue a publicly-trusted certificate.** `config_type` accepts
`ISSUED_BY_INTERNAL_CA`, `MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA` and
`IMPORTED`, and nothing else. ACM's headline behaviour - free, DNS-validated,
browser-trusted, renewed forever with no action - has no equivalent here.

| Path | Publicly trusted? | Renewal |
|---|---|---|
| `ISSUED_BY_INTERNAL_CA` | no | Oracle-managed via `certificate_rules` |
| `MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA` | no | Oracle-managed |
| `IMPORTED` | only if the PEM already is | **none - self-managed** |

Anything an external merchant, browser or mobile SDK connects to must be
`IMPORTED` from an ACME client or a purchased certificate, and must have an
expiry alarm built against the `self_managed_renewal` output. Setting
`trust_domain = "public"` on a CA-issued certificate is rejected at plan time.

## Parity summary

5 FULL / 2 PARTIAL / 1 SUBSTITUTE / 3 NONE. Gaps, each commented at the point
of divergence in `main.tf`:

- features 1, 2, 7 (public issuance, DNS-01 validation, CT logging) - **NONE**
- feature 4 (automatic renewal) - **PARTIAL**, CA-issued only
- feature 9 (export to non-LB compute) - **PARTIAL**, Certificates Runtime API,
  outside this module's management-plane resources, unverified
- feature 10 (`wait_for_validation`) - **SUBSTITUTE**, generic `timeouts`

## Notable structural differences

- **No dependency on the `dns` module.** There is no ownership proof to
  publish, so unlike GCP's `certificate-manager` (which must hand
  `dns_authorization_records` to `cloud-dns`) this module is standalone.
- **It can own a root CA.** Neither the AWS nor the GCP module does. Off by
  default (`create_root_ca = false`); whether the CA belongs here or in a
  shared platform unit is acm.md oracle-gate item 2, not yet consulted.
- **A Vault key is a hard prerequisite for any CA.**
  `oci_certificates_management_certificate_authority.kms_key_id` is required
  by the provider; there is no Oracle-managed-key option.
