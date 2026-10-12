# composition/database - OCI Database with PostgreSQL

The transactional data tier of the payments platform on OCI. Port of
`terraform/aws/modules/composition/database` (Aurora PostgreSQL provisioned
cluster). Strategy: **DIRECT-RESOURCE** - a registry search for OCI PostgreSQL
modules returned nothing, so there is no module to wrap, unlike the GCP port
which wraps `GoogleCloudPlatform/alloy-db/google`.

The module keeps the AWS name rather than following GCP's product-named split
(`alloydb` / `cloud-sql`), because OCI has exactly one managed PostgreSQL
offering. Full rationale: `docs/multi-cloud-parity/oci/modules/database.md` §5.

Parity headline from the check sheet: **9 FULL / 8 PARTIAL / 2 SUBSTITUTE /
5 NONE**. Nothing in this module is claimed as FULL where the check sheet
scored it lower.

---

## Read this before you use it

Four things a reader will otherwise get wrong.

### 1. TLS is mandatory and there is no off-switch

OCI Database with PostgreSQL "only allows the `hostssl` connection type in the
`pg_hba.conf` file"; "non-SSL connections are not supported due to regulatory
and compliance requirements"; `ssl_min_protocol_version` and
`ssl_max_protocol_version` are read-only at TLSv1.2.

The shared AWS catalog unit sets `custom_parameter_group_parameters =
[{ name = "rds.force_ssl", value = "0" }]`, so **all seven AWS live roots today
permit plaintext PostgreSQL**. That cannot be reproduced. This module exposes no
TLS variable, deliberately - a knob that does nothing is worse than none.

**This is the one application-visible break in the port.** Every connection
string (hyperswitch-router, superposition, decision-engine, grafana, the locker,
the db-migration jobs) must carry `sslmode=require` at minimum *before* this
unit is applied. A client with `sslmode=disable` gets `no pg_hba.conf entry for
host ... no encryption`. Discovered at apply time, that looks like a network
outage, not a TLS problem, and every application fails simultaneously.

For `verify-ca` / `verify-full`, distribute the `ca_certificate` output through
external-secrets.

### 2. `ap-mumbai-1` has one availability domain

Multi-node in a single-AD region means the nodes are spread across the three
**fault domains inside that one AD**. That is not AD-level fault tolerance and
must not be reported as one. AWS `ap-south-1` has three AZs and the live AWS
unit pins instances to `${region}a` and `${region}b`, so an AZ loss is
survivable by design; in `ap-mumbai-1` an AD-scope outage is a **regional**
outage for the payments database.

`instance_count` therefore defaults to **2, not 1** - deliberately diverging
from the GCP precedent's single ZONAL dev AlloyDB. A single-node system drops
Oracle's SLA from 99.99% / RTO < 2 min to 99.9% / RTO < 20 min, and is the only
configuration where fault-domain spread and the "within a few seconds" failover
are not in play at all.

`is_regionally_durable` defaults to **`false`**, and the module resolves the
availability domain itself. This changed in C13, and the paragraph that used to
sit here claimed the opposite - that `true` "costs nothing in a single-AD region
and makes the same configuration right the moment the stack lands in a multi-AD
one". The first real create call in `ap-mumbai-1` returned
`400-InvalidParameter, Invalid isRegionallyDurable: ... This feature is only
supported in 3 AD regions. Please set the parameter as false and specify
availabilityDomain.` It is a choice between two placement models - regional
("nodes are placed in different availability domains") and AD-local ("nodes are
placed in different fault domains in the same availability domain") - and the
regional one has nothing to express with one AD. Check sheet open question 9.2
is closed by that error, on the branch it predicted.

`false` is not a weaker posture in `ap-mumbai-1`: under either value a two-node
system lands in the same three fault domains of the same AD. It is weaker in one
respect only, and that respect is `FORCE-NEW` - `storage_details.availability_domain`
and `system_type` are non-updatable, so a Mumbai that later gains ADs would need
a **replace** of the db system to take regional placement, not an update. A
precondition in `outputs.tf` now checks the flag against a real
availability-domain listing, so a wrong value fails at plan instead of at create.

### 3. Warm standby's RPO floor is 300 seconds, and failover is manual

There is no `aws_rds_global_cluster` counterpart - no global object, no global
identifier, no storage-layer replication. Replication with Warm Standby (GA
2026-06-16) is WAL streaming between two independent db systems.

| | Aurora Global Database | Warm standby |
|---|---|---|
| Steady-state lag | "typically under a second" | not published |
| Enforceable RPO floor | 20 s (`rds.global_db_rpo`) | **300 s** |
| Unplanned failover | managed API / automated | **manual only** |
| RTO | "less than 1 minute" | human-paged, tens of minutes |
| Old primary rejoins | automatic | manual, two steps |

With `is_rpo_enforced = true` the loss is bounded at `rpo_in_seconds`, but the
**primary switches to read-only** when lag exceeds it - a DR feature that can
cause a payments outage. With it `false` the window is unbounded. There is no
third setting.

It is **off by default** (`enable_warm_standby = false`) and that default is a
decision, not an omission: the binding call is
`docs/multi-cloud-parity/oci/data-tier-strategy.md` §8 - Option B for dev
(in-region HA plus cross-region backup copy), with this path written and
validated but not instantiated, so that turning it on later is a `values`
change and not a module change.

### 4. Restore is unavailable while warm standby is enabled

"Restore Database system isn't supported for Replication with Warm Standby
database systems (primary & warm standby)." The DR feature and the restore
feature are mutually exclusive on the same db system, and `outputs.tf` rejects
the combination at plan time.

Sequence it: create from backup or PITR *first*, then establish the standby
relationship. To restore a replicated pair, break replication, restore,
re-establish. `aws/live/prod/eu-west-1` was in fact created from a snapshot, so
this is a path the stack has really used.

---

## Two more gaps that have no workaround

**No deletion protection.** `oci_psql_db_system` has no `deletion_protection`
argument in provider 9.0.0 - verified by dumping the provider's own JSON schema,
not asserted from memory. All seven AWS roots set `deletion_protection = true`
plus `global_deletion_protection = true`; none of it ports. There is no
service-side veto on destroying the payments database, and the force-new set is
not small (`db_version`, `storage_details.system_type`,
`storage_details.availability_domain`, `network_details.subnet_id`).

Mitigation is three layers, only the third of which is real:
1. `lifecycle { prevent_destroy = true }`, hardcoded in `main.tf`. Terraform
   forbids a variable there ("Variables may not be used here"), so
   `var.prevent_destroy` cannot switch it; the variable is a declared-intent
   flag whose `false` value raises a precondition explaining the teardown
   procedure. Enforced by Terraform, not by OCI - it stops accidents, not a
   determined operator or a corrupted state file.
2. `backup_policy.retention_days`, so data survives deletion of the system.
3. An IAM policy in the compartment denying the delete verb on
   `postgres-db-systems` outside a break-glass group. **The only control that
   survives a wrong `terraform apply`**, and it lives outside this module.

**No customer-managed encryption key.** Data is encrypted at rest with
Oracle-managed keys only. There is no key argument on the resource and no
encryption-key section in the console create flow. AWS's nested
`terraform-aws-modules/kms/aws` module, `enable_key_rotation`, the
`multi_region = true` on passive roots, and three `module_kms_key_*` outputs all
disappear. This module has no `kms.tf` and no CMEK variable, because an empty
toggle would imply a capability that does not exist. The `encryption_at_rest`
output states the posture explicitly.

For a PCI-scope payments database this is an audit finding to be accepted in
writing by the security owner. What remains: `pgcrypto` for application-level
encryption (available by default), and a customer-managed key on the OCI Vault
secret that holds the admin credential.

---

## What else changed shape

| AWS | Here | Why |
|---|---|---|
| `cluster_instances` map (per-instance class, AZ, `promotion_tier`) | `shape` + `instance_ocpu_count` + `instance_memory_size_in_gbs` + `instance_count` | Sizing is db-system-level on OCI; every node is identical and there is no failover-priority lever. PARTIAL |
| `backup_retention_period = 7` (one number) | `backup_retention_days` **and** `pitr_restore_days` | Two independent policies. Setting only the first ships a database with no PITR, so `pitr_restore_days` has no default. PARTIAL |
| `preferred_backup_window = "00:51-01:21"` | `backup_start_hour = "00"` | Hour granularity only. The module appends the `":00"` the API's `backupStart` actually wants (C12); the backup starts **51-81 minutes earlier** than the AWS window, not the "up to 9 minutes" this row used to claim. PARTIAL |
| `aws_db_subnet_group` over `database_subnet_ids` | `subnet_id` (singular) | No subnet-group concept. FULL |
| `aws_security_group` -> `security_group_id` | `oci_core_network_security_group` -> `nsg_id` | NSGs are membership-based and referenceable as a rule source. The NSG is created **empty**; the security-last stack phase writes the rules. FULL |
| `manage_master_user_password` | `random_password` + `oci_vault_secret` | No service-managed generation or rotation. The alloydb pattern, for the identical reason. PARTIAL |
| `enabled_cloudwatch_logs_exports` | `oci_logging_log_group` + `oci_logging_log` | Same capability, separate resources. FULL |
| `performance_insights_*` + `monitoring_*` (6 vars) | `query_insights_enabled` + `query_insight_types` | Retention is 7 days, the only supported value, matching the live AWS value - but it is **sent explicitly, not defaulted**: the API rejects `retentionPeriodInDays` as `'null'` at create even though four Oracle artefacts document a 7-day system default (C14). FULL |
| Aurora reader endpoint | `is_reader_endpoint_enabled` | Capped at **8 Gbps aggregate**; `instance_endpoints` is the client-side-balancing escape hatch. PARTIAL |

Dropped outright, with no substitute modelled, because the capability does not
exist (all NONE in the check sheet):

- **Write forwarding** (`enable_global_write_forwarding`,
  `enable_local_write_forwarding`) - no counterpart in any form. `false`/unset
  in all seven AWS roots, so zero blast radius.
- **IAM database authentication** - Kerberos exists (`kerberos_auth_details`)
  but requires a KDC and does not let a cloud principal mint a short-lived DB
  token. Not the same capability, so not modelled speculatively. `false` in all
  seven roots.
- **Serverless autoscaling** (`scaling_configuration`,
  `serverlessv2_scaling_configuration`) - no ACU model, no auto-pause, no
  capacity tracking. `var.state = "INACTIVE"` is exposed as the nearest cost
  lever and is *not* autoscaling. Unset in all seven roots.
- **TLS off-switch** - see above.
- **Deletion protection** - see above.

Not creatable in Terraform at all: **per-application databases**. OCI creates
only the default `postgres` database and provider 9.0.0 has no
`oci_psql_database` resource, so `hyperswitch_db` / `superposition_v2` and their
owners need a `db-migration` job or a `psql` step. GCP hit the identical wall on
AlloyDB. Check sheet open question 9.4.

---

## Provider verification

Every argument in this module was read out of `oracle/oci` **9.0.0**'s own JSON
schema (`terraform providers schema -json`) on 2026-09-03, not from memory.
Resources used: `oci_psql_db_system`, `oci_psql_configuration`,
`oci_psql_backup`, `oci_core_network_security_group`, `oci_vault_secret`,
`oci_logging_log_group`, `oci_logging_log`, `random_password`; data source
`oci_psql_db_system_connection_detail`.

Validation performed: `terraform fmt -check -recursive` clean,
`terraform init -backend=false` + `terraform validate` clean, and each
`outputs.tf` precondition exercised against the combination it is meant to
reject.
