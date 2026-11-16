# grafana (OCI)

The OCI port of `terraform/aws/modules/application-resources/grafana`.

Check sheet: `docs/multi-cloud-parity/oci/modules/grafana.md`.
Database half: `docs/multi-cloud-parity/oci/modules/database.md` - inherited
wholesale, not restated.

84 AWS variables become roughly 20. Almost the whole reduction is `database.md`'s
own ~70-to-~34 finding plus collapsing that surface into one `database_config`
object instead of ~70 flattened `database_*` variables.

## Four things to know

1. **No `role_arn`, no policy object.** This module emits `policy_statements` -
   exactly **three** per cluster - for the ONE shared, environment-scoped policy
   owned by `oke-workload-identity`.

2. **Read the verbs.** `read metrics`, `read log-content`, `read log-groups`.
   Not `use metrics` / `use log-content`, which are the *publish* verbs
   `otel-collector` needs. `identity-model.md` section 3.5 documents only the
   write side; the read verbs were verified while porting this module and are
   recorded in that document's header correction. A plan showing `use metrics`
   here is wrong.

3. **The observability data path is real; the identity path is the gap.** OCI
   Monitoring and Logging are queryable and Oracle maintains two Grafana
   plugins for them. But both plugins document exactly two auth modes -
   Instance Principal (via a dynamic group) and User Principal (a local API-key
   file) - and **neither names workload identity**. Both are OCI-Go-SDK based
   and the SDK has supported workload identity for years, so whether the binary
   implements the path is undocumented rather than known-absent. Check sheet
   section 9 Q1 is the highest-leverage question on that sheet; it is
   answerable by reading `github.com/oracle/oci-grafana-metrics`'s
   auth-provider selection code.
   - If yes: leave `datasource_api_key_vault_secret_id` null. Zero exception.
   - If no: set it to a Vault secret OCID (never a credential value) and accept
     a rotated static API key, the same shape `vector` and `otel-collector`
     already take. `datasource_uses_static_credential` goes true in the plan.
   - **Rejected**: a dedicated dynamic group over Grafana's node pool. Trades a
     credential file for instance-principal blast radius.

4. **TLS is mandatory and it changes Grafana's own config.** OCI Database with
   PostgreSQL permits only `hostssl`; there is no `rds.force_ssl = 0`
   equivalent. Set `GF_DATABASE_SSL_MODE` to `require`/`verify-ca`/`verify-full`
   **before** applying, and mount `database_ca_certificate` for the verify-*
   modes. Discovered at apply time it surfaces as a generic connection error,
   not an obviously TLS-shaped one.

## Cross-region DR is deliberately not built

`database_create_global_cluster` and its six siblings are dropped, and
`enable_warm_standby` is not exposed on `database_config`. The reason is about
this consumer, not the technology: OCI's PostgreSQL service caps at **eight db
systems per tenancy per region**, every warm standby consumes a second slot, and
Grafana's database holds dashboards and alert rules - not payment data, not on
the request path. Spending one of eight on it while the payments database
competes for the same budget is the wrong default. A lost Grafana is
re-provisioned from a routine backup. Cross-region *backup copy* remains
available via `database_config.backup_copy_regions`. Oracle gate item, **not yet
consulted**.

## The database adds zero statements

OCI Database with PostgreSQL has no IAM-principal-to-database-user auth path
(`database.md` section 4.14, verdict NONE). Grafana connects with a username and
password over TLS, not a workload-identity token, so a database dependency does
not translate into extra policy statements.

Two contingent statements are *not* included, pending open questions: `inspect
compartments` for the plugins' compartment picker (would likely need a
tenancy-root-scoped grant - a structural exception, not one more statement in
the same object), and `read secret-bundles` if the chart reads Vault directly
rather than via the external-secrets relay.

## No per-app database

OCI creates only the default `postgres` database and provider 9.0.0 has no
`oci_psql_database` resource, so a `grafana` database is a manual `psql` step.
GCP's AlloyDB port hit the identical wall. `database_name` is emitted as an
explicit null so the gap is visible.
