# composition/database - OCI Database with PostgreSQL

The transactional PostgreSQL data tier for OCI. Direct-resource implementation
against `oci_psql_db_system` plus related logging, backup, vault-secret and
network-security resources.

## Read this before you use it

1. **TLS is mandatory and cannot be disabled.** OCI Database with PostgreSQL
   only allows the `hostssl` connection type in `pg_hba.conf`; the provider
   exposes no TLS off-switch. Every client must use `sslmode=require` (or
   stronger) before this module is applied — a `sslmode=disable` client fails
   with "no pg_hba.conf entry for host". Distribute `ca_certificate` via
   external-secrets for `verify-ca`/`verify-full`.

2. **`ap-mumbai-1` has one availability domain.** Multi-node instances spread
   across the three fault domains inside that single AD — not AD-level fault
   tolerance. `instance_count` defaults to 2 (a single node drops the SLA to
   99.9% / RTO < 20 min). `is_regionally_durable` defaults to `false` because
   the regional placement model has nothing to express with one AD; leave it
   `false` in single-AD regions.

3. **Warm standby's RPO floor is 300 seconds and failover is manual.** There is
   no global-object replication; warm standby is WAL streaming between two
   independent db systems. With `is_rpo_enforced = true` the primary switches
   **to read-only** when lag exceeds `rpo_in_seconds` — a DR feature that can
   cause a payments outage. It is off by default (`enable_warm_standby = false`).

4. **Restore is unavailable while warm standby is enabled.** The two features
   are mutually exclusive. Create from backup/PITR first, then establish the
   standby relationship.

## Known gaps

- **No deletion protection.** `oci_psql_db_system` has no
  `deletion_protection` argument. Mitigation is layered: a hardcoded
  `lifecycle { prevent_destroy = true }`, `backup_policy.retention_days`, and
  (the only control that survives a wrong `terraform apply`) an IAM policy
  denying the delete verb on `postgres-db-systems` outside a break-glass group.
- **No customer-managed encryption key.** Data is encrypted at rest with
  Oracle-managed keys only; there is no CMEK argument. `encryption_at_rest`
  states the posture explicitly. `pgcrypto` is available for application-level
  encryption.
- **No per-application databases.** OCI creates only the default `postgres`
  database; application databases (`hyperswitch_db`, etc.) need a db-migration
  job or a `psql` step.

## Provider verification

Arguments are verified against the `oracle/oci` 9.0.0 provider schema.
Validation: `terraform fmt -check -recursive`, `terraform init -backend=false`
+ `terraform validate`, and each `outputs.tf` precondition exercised against
the combination it is meant to reject.