# composition/locker (OCI)

The card vault - `hyperswitch-card-vault`, internally "tartarus". The one
component that stores cardholder data, and the narrowest PCI-DSS scope boundary
in the platform.

Port of `terraform/aws/modules/composition/locker` (7 files, 1067 lines, 22
variables, 31 outputs, 3 nested modules), consumed by 8 of 11 AWS live roots.
Check sheet: `hyperswitch-infra/docs/multi-cloud-parity/oci/modules/locker.md`.

Strategy: **DIRECT-RESOURCE**. No OCI registry module clears the framework's
verified / >50k-downloads / 18-month bar for KMS, Vault Secrets, PostgreSQL,
Compute or Load Balancer.

## What this module owns

| File | Resources | Feature |
|---|---|---|
| `kms.tf` | `oci_kms_vault`, `oci_kms_key`, `oci_kms_vault_replication` | 14 (FULL) |
| `secrets.tf` | `oci_vault_secret` (server-side generated) | 2 (SUBSTITUTE, redesigned) |
| `network.tf` | `oci_core_network_security_group` (empty) | 5 (FULL) |
| `database.tf` | `oci_psql_db_system` + connection-detail data source | 15 (FULL), 16 (SUBSTITUTE), 17 (PARTIAL), 19 (NONE) |
| `configuration.tf` | `oci_psql_configuration` | 18 (NONE - and stronger for it) |
| `logging.tf` | `oci_logging_log_group`, `oci_logging_log` | 6 (FULL) |
| `identity.tf` | **none** - renders grant objects only | 7-10 (SUBSTITUTE) |

Nine resource addresses in total. Features 1, 11, 12 and 13 are **N/A**, not
ported - see below.

## Five things that will surprise a reader of the AWS module

1. **There is no compute tier and no load balancer.** The card-vault binary
   runs as an OKE workload through the same Helm/GitOps flow as every other
   application, following what GCP actually ships today after building,
   proving, and then deliberately tearing down a Packer + MIG + internal-LB
   pipeline for this exact workload. **This is an oracle-gate decision
   (check sheet §8 decision 1) and the gate has not been convened.**
2. **No private key is ever generated.** `hashicorp/tls` is not a dependency.
   The AWS module's `tls_private_key` writes an RSA-4096 private key into
   Terraform state in plaintext, in all 8 live roots today. Interactive access
   on OCI is the Bastion service, the analogue of the SSM Session Manager path
   the org already uses. If a key is ever needed, OCI Vault generates it
   server-side (`generation_type = "SSH_KEY"`), which is stronger than
   `ephemeral "tls_private_key"`.
3. **No password is ever a Terraform value.** OCI Vault generates the database
   admin password itself. There is no plaintext-password input and no password
   output. This diverges from the sibling `composition/database`, which uses
   `random_password` and accepts the value landing in state.
4. **The module's key does not encrypt the database.** `oci_psql_db_system` has
   no customer-managed-key argument at all in provider 9.0.0. The database is
   encrypted under an Oracle-managed key. The `encryption_at_rest` output says
   so explicitly rather than letting a consumer assume otherwise.
5. **TLS to the database is mandatory and cannot be disabled.** The live AWS
   locker unit sets `rds.force_ssl = "0"` on the card vault's own database.
   Every connection string needs `sslmode=require` at minimum, plus the
   `db_ca_certificate` output for `verify-ca`/`verify-full`, **before** first
   apply.

## Security posture versus AWS

| Control | Verdict |
|---|---|
| Encryption in transit (database) | **Stronger** - cannot be disabled; AWS's live config disables it |
| Secret storage / key material | **Stronger** - nothing reaches Terraform state |
| Access control (workload identity) | **Stronger** - the AWS bundle's `AmazonS3FullAccess` and unscoped `ecr:*` are not replicated |
| Key custody (component key) | Equal - HSM-backed both sides; `VIRTUAL_PRIVATE` available as an option |
| Network isolation | Equal - NSGs, same peer-group referencing model |
| Audit logging | Equal |
| Encryption at rest (database) | **Weaker** - no customer-managed key exists |
| Deletion protection (database) | **Weaker** - `lifecycle.prevent_destroy` only, not service-enforced |
| Multi-region DR (database) | **Weaker** - 300 s RPO floor, manual failover, two independent systems |

The three weaker rows are disclosed limits of OCI's PostgreSQL service with no
current workaround, not implementation shortcuts. The encryption-at-rest row
needs a PCI-scope sign-off separate from the shared database's.

## Provider verification

Every argument, block name and enum used here was read from
`terraform providers schema -json` against **oracle/oci 9.0.0**. Secret
generation types and templates were verified against
`docs.oracle.com/en-us/iaas/Content/secret-management/Concepts/manage-secrets.htm`.

## Validation reached

Rung 1 (`terraform validate`) and rung 2 (`terraform fmt -check`) pass. Rungs
3-5 (stack generate, `terragrunt plan`, plan-vs-check-sheet review) are the
orchestrator's, as they were for wave 1.
