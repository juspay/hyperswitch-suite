# composition/spanner

Cloud Spanner with the **PostgreSQL interface** - a horizontally scalable,
strongly consistent database that speaks PostgreSQL syntax.

This is *not* a drop-in replacement for `composition/alloydb`. Read the two
caveats below before wiring anything to it.

## Caveat 1: the PostgreSQL interface is not the PostgreSQL wire protocol

`database_dialect = "POSTGRESQL"` gives you PostgreSQL **syntax and
semantics** - `text` columns, `SERIAL`, standard PG functions, PG error codes.
It does **not** give you the PostgreSQL **wire protocol**.

A libpq client - psql, diesel, tokio-postgres, sqlx, pgbouncer - cannot open a
connection to the database this module creates. Two ways to reach it:

| Path | What it means |
|---|---|
| **PGAdapter** | A proxy that speaks the PG wire protocol on one side and Spanner's gRPC API on the other. Runs as a sidecar next to the app, or as a Deployment + Service on GKE. Existing PG clients then work unmodified. |
| **Spanner client libraries** | The app talks gRPC directly, in PG dialect. No proxy, but the app's data layer has to be written for it. |

**This module deliberately stops at the data tier.** It does not deploy
PGAdapter. Until something does, the databases it creates are reachable only
by Spanner client libraries. The `pgadapter_connection` output carries exactly
the `{ project, instance, databases }` triple PGAdapter needs.

## Caveat 2: there is no network, and no password

Two structural breaks from every other data module in this catalog:

- **No VPC attachment.** Spanner is a global, IAM-authenticated API endpoint.
  There is no `network_id`, no Private Service Access range, no private IP, and
  no dependency on `composition/vpc-network`. Nothing to peer, and no firewall
  rule to write.
- **No bootstrap user.** There is no username, no password, no Secret Manager
  entry, and no `random_password`. Access is `roles/spanner.databaseUser`
  granted to a principal, through `database_iam_members`.

If you are porting a mental model from `composition/alloydb` or
`composition/cloud-sql`, those are the two things that will surprise you.

## Why native resources instead of the registry module

`composition/alloydb` wraps `GoogleCloudPlatform/alloy-db` to work around a
provider bug. This module does the opposite, for a concrete reason:
`GoogleCloudPlatform/cloud-spanner` (v1.2.1) exposes databases through a
`database_config` object that has **no `database_dialect` key**. It can only
ever create `GOOGLE_STANDARD_SQL` databases, so a PostgreSQL-dialect database
is not expressible through it.

Do not "simplify" this back to the registry module.

## Sizing

Exactly one of the three must be set - the API rejects zero or more than one:

```hcl
instance_size = { processing_units = 100 }              # dev floor, 1/10 node
instance_size = { num_nodes = 1 }                       # 1 node = 1000 PU
instance_size = { autoscaling = {                       # managed scaling
  min_nodes = 1
  max_nodes = 3
} }
```

`processing_units` must be a multiple of 100 below 1000 and a multiple of 1000
at or above it. Autoscaling limits must use one unit consistently - nodes *or*
processing units, never a mix. All three rules are enforced by variable
validation rather than left to a confusing API rejection.

## Topology

`instance_config` is a **topology**, not a region. It defaults to
`regional-<region>`, which replicates across three zones in one region.

Multi-region configs (`nam3`, `eur3`, `asia1`) replicate across regions with a
higher availability SLA. Note that `asia1` is Tokyo/Osaka/Seoul - **there is no
India multi-region config**, so an `asia-south1` deployment that wants
multi-region has to accept cross-continent placement.

`instance_config` is immutable after creation.

## Backups

Three independent mechanisms, easily confused:

| Mechanism | Where | What it gives |
|---|---|---|
| `version_retention_period` | per database | Point-in-time recovery on the live database, 1h-7d |
| `backup_schedule` | per database | Independent copies that outlive the database |
| `default_backup_schedule_type` | instance | A default schedule for databases created *outside* Terraform |

Incremental schedules (`backup_schedule.type = "INCREMENTAL"`) require
`edition` `ENTERPRISE` or above. On `STANDARD` the module fails with an
explicit precondition rather than letting the API reject the apply.

A backup schedule is owned by its database and is deleted with it. The backups
it already took are **not** - those are governed by `retention_duration`, and
are what `force_destroy` on the instance exists to clean up.

## Deletion protection

Two separate levers, which do different things:

| Input | Scope | Blocks |
|---|---|---|
| `deletion_protection` | Terraform only | `terraform destroy` of the database. Must be flipped to `false` and applied **first**, as a separate step - the same two-step constraint `gke` and `alloydb` have. |
| `databases.<name>.enable_drop_protection` | API-wide | Deletion through *any* interface, and it also blocks deletion of the parent **instance**. |

## DDL is not a migration tool

`databases.<name>.ddl` runs atomically with database creation. Terraform does
not drift-detect it. Appending a statement is an in-place update; **editing or
removing an existing statement plans a replacement of the database**, which
destroys its data. Use it for bootstrap schema only, and run real migrations
through a migration tool.

DDL must be written in the database's own dialect - PostgreSQL syntax for a
`POSTGRESQL` database.

## CMEK

Spanner attaches CMEK **per database**, not per instance the way AlloyDB does.
Set `encryption_key_name` for a module-wide key, or
`databases.<name>.kms_key_name` per database, or `kms = { create = true }` to
have the module build a keyring and key.

The Spanner **service agent** - not the operator, not the workload - is the
principal that encrypts, so it must hold `cryptoKeyEncrypterDecrypter` on the
key before the database is created. `kms.tf` provisions the agent with
`google_project_service_identity` and grants it, and the database `depends_on`
that grant explicitly. `composition/alloydb` documents the same trap, where
omitting it let the cluster create and then failed the instance part-way
through.

The single-key `kms_key_name` only covers a single-region `instance_config`. A
multi-region config needs one key per region (`kms_key_names`, plural), which
this module does not expose - a precondition rejects that combination rather
than letting it fail at apply.

## Usage

```hcl
module "spanner" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/spanner?ref=gcp-spanner-v0.1.0"

  project_id  = "hyperswitch-dev"
  environment = "dev"
  region      = "asia-south1"

  instance_size = { processing_units = 100 }

  databases = {
    hyperswitch = {
      database_dialect         = "POSTGRESQL"
      version_retention_period = "3d"
    }
  }

  database_iam_members = [
    {
      database = "hyperswitch"
      role     = "roles/spanner.databaseUser"
      member   = "serviceAccount:pgadapter@hyperswitch-dev.iam.gserviceaccount.com"
    },
  ]
}
```

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_id` | GCP project | required |
| `environment` | `dev` / `integ` / `prod` / `sandbox` | required |
| `region` | Derives `instance_config` and places the CMEK keyring | required |
| `project_name` | Name prefix | `hyperswitch` |
| `instance_id` | 6-30 chars | `<environment>-<project_name>-spanner` |
| `instance_display_name` | 4-30 chars | `instance_id` |
| `instance_config` | Topology | `regional-<region>` |
| `edition` | `STANDARD` / `ENTERPRISE` / `ENTERPRISE_PLUS` | `STANDARD` |
| `instance_size` | Exactly one of `processing_units` / `num_nodes` / `autoscaling` | `{ processing_units = 100 }` |
| `default_backup_schedule_type` | `NONE` / `AUTOMATIC` | `NONE` |
| `force_destroy` | Delete backups when destroying the instance | `false` |
| `deletion_protection` | Default Terraform delete guard per database | `true` |
| `databases` | Map keyed by database name | `{ hyperswitch = {} }` |
| `instance_iam_members` | Instance-level grants | `[]` |
| `database_iam_members` | Database-level grants | `[]` |
| `kms` | `{ create = true }` to build a keyring/key | `null` |
| `encryption_key_name` | Existing CMEK key self-link | `null` |
| `labels` | Extra labels | `{}` |

## Outputs

| Name | Description |
|---|---|
| `instance_id` | Instance ID |
| `instance_name` | `projects/<p>/instances/<i>` |
| `instance_config` | Topology in effect |
| `instance_state` | `CREATING` or `READY` |
| `edition` | Edition in effect |
| `capacity` | `{ num_nodes, processing_units, autoscaling }` |
| `database_ids` | Database IDs by name |
| `database_names` | Fully-qualified database names by name |
| `database_dialects` | Dialect by name |
| `postgres_database_names` | The `POSTGRESQL`-dialect databases only |
| `pgadapter_connection` | `{ project, instance, databases }` for PGAdapter |
| `backup_schedule_ids` | Backup schedule IDs by database |
| `kms_key_name` | CMEK key in use, if any |
| `service_agent_email` | Spanner service agent granted on the key, if CMEK |
