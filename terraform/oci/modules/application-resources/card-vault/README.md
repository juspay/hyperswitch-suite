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