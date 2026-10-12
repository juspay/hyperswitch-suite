# composition/locker (OCI)

The card-vault data tier ("hyperswitch-card-vault") — the component that stores
cardholder data, and the narrowest PCI-DSS scope boundary in the platform.

## What this module creates

| File | Resources |
|---|---|
| `kms.tf` | `oci_kms_vault`, `oci_kms_key`, `oci_kms_vault_replication` |
| `secrets.tf` | `oci_vault_secret` (server-side generated) |
| `network.tf` | `oci_core_network_security_group` (created empty; rules come from the security-last stack phase) |
| `database.tf` | `oci_psql_db_system` + connection-detail data source |
| `configuration.tf` | `oci_psql_configuration` |
| `logging.tf` | `oci_logging_log_group`, `oci_logging_log` |
| `identity.tf` | renders grant objects only — no identity resources |

The card-vault binary is **not** deployed here; it runs as an OKE workload
through the same Helm/GitOps flow as every other application.

## Security posture

- **No private key is ever a Terraform value.** OCI Vault generates any
  server-side SSH key (`generation_type = "SSH_KEY"`); `hashicorp/tls` is not a
  dependency.
- **No password is ever a Terraform value.** OCI Vault generates the database
  admin password; there is no plaintext-password input or output.
- **TLS to the database is mandatory.** Every connection needs `sslmode=require`
  (or stronger) before first apply — the provider exposes no TLS off-switch.
- **The module's KMS key does not encrypt the database.** `oci_psql_db_system`
  has no customer-managed-key argument; the database is Oracle-managed-key
  encrypted. The `encryption_at_rest` output states this explicitly.

The weaker rows versus the AWS original are disclosed limits of OCI's
PostgreSQL service, not implementation shortcuts: no customer-managed database
encryption key, deletion protection is `lifecycle.prevent_destroy` only (not
service-enforced), and multi-region DR has a 300 s RPO floor with manual
failover. The encryption-at-rest gap needs a PCI-scope sign-off.

## Validation

`terraform validate` and `terraform fmt -check` pass.