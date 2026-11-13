# card-vault (OCI)

Two unrelated jobs in one Terraform state, exactly as on AWS:

1. **An identity contribution.** No hardcoded policy, no policy object. The AWS
   module is a generic role factory; on OCI all three of its permission
   surfaces (`aws_managed_policy_names`, `customer_managed_policy_arns`,
   `inline_policies`) collapse into one `extra_statements` list, because OCI has
   exactly one way to grant anything: an authored statement. The single live
   grant is `use keys` on **hyperswitch's** key — a key this module does not own;
   an asymmetry that is real on AWS too.

2. **An optional dedicated PostgreSQL database**, nested rather than depended-on,
   so it provisions in stack phase 3 alongside the app rather than in phase 1
   with the shared database. Same as AWS.

## Optional database backup source

With `create_database = true`, `database_config.source_backup_id` optionally
forwards a backup OCID to the existing nested `composition/database` module.
It defaults to `null`: the default create path starts with only the `postgres`
database; a backup source can carry existing application databases. A supplied
source creates from that backup in `database_config.subnet_id`, using the same
owner and address, `module.database[0].oci_psql_db_system.this`. It does not add
a second database module. With `create_database = false`, no database is created,
even if a backup source is supplied. Backup sources and warm standby are
mutually exclusive, enforced by the composition module.

This is a **create-time source**, not an in-place restore, import, or state
adoption mechanism. The existing database remains tracked at its nested address;
this change requires no import, move, or removal of state. Changing an existing
database's subnet requires replacement, which the composition module's hardcoded
`prevent_destroy = true` will block. Do not remove that protection for a subnet
cutover. Restore/adoption and application-data cutover require a separately
approved operational plan; this passthrough does not migrate current data.
Keep the deployed source `null` and the existing subnet until that cutover is
approved.

The admin username and external `vault_secret` reference/version are passed
through unchanged. With an existing external secret, Terraform neither generates
a password nor retrieves the secret value. `database_name` remains `null`:
this wrapper does not discover database names contained in a backup.

### Offline regression tests

Using Terraform 1.7+ (mock providers), Python 3, and Bash:

```bash
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
bash tests/verify-plans.sh
```

The verifier runs native `terraform test -json -verbose` with mocked OCI and
random providers, then checks child-resource plans without adding production
outputs. It covers an omitted backup source, a supplied synthetic backup and
requested subnet, disabled database creation, and preserved external Vault
metadata with no password generation or secret retrieval. It makes no OCI calls
and does not access deployed state.

## Statement budget: one

The actual grant count is **1 statement per cluster per service account** — the
KMS statement. Do not size the shared policy object's headroom off a broader
estimate.

## Unresolved fork you are inheriting

AWS grants this workload app-level KMS encrypt/decrypt. **GCP's port of the
same module grants nothing at all**, routing encryption through the database
layer's CMEK instead. Neither is obviously the target, and OCI Database with
PostgreSQL supports no customer-managed key at all, which weakens the case for
GCP's choice. Leaving `kms_key_id` null adopts GCP's shape; setting it adopts
AWS's.

## What is deliberately not here

- STS/role plumbing (`role_name`, `role_path`, `max_session_duration`,
  `force_detach_policies`) — there is no role.
- `assume_role_principals` — there is no assumable object.
- `aws_managed_policy_names` — OCI publishes suggested statement *text*, not
  attachable named objects.
- `customer_managed_policy_arns` — folded into `extra_statements`.
- `host_domains` — a DNS/routing concern that was already a pure passthrough
  with no infrastructure effect.
- `database_create_global_cluster` and siblings — no global-cluster object on
  OCI. Cross-region DR is `enable_warm_standby` + `primary_db_system_id`,
  exposed under their real names.
