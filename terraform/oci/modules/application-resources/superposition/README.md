# superposition (OCI)

The OCI port of `terraform/aws/modules/application-resources/superposition`.

Check sheet: `docs/multi-cloud-parity/oci/modules/superposition.md`.
Database half: `docs/multi-cloud-parity/oci/modules/database.md` - **not**
restated here.

## What this module is

Two unrelated jobs in one Terraform state, exactly as on AWS:

1. **An identity contribution.** No hardcoded policy, no policy object. The AWS
   module is a generic role factory; on OCI all three of its permission
   surfaces (`aws_managed_policy_names`, `customer_managed_policy_arns`,
   `inline_policies`) collapse into one `extra_statements` list, because OCI has
   exactly one way to grant anything: an authored statement. The single live
   grant is `use keys` on **hyperswitch's** key - a key this module does not own,
   an asymmetry that is real on AWS too.

2. **An optional dedicated PostgreSQL database**, nested rather than depended-on,
   which means it provisions in stack phase 3 alongside the app rather than in
   phase 1 with the shared database. Same as AWS.

## Statement budget: one

`identity-model.md` section 1.2 estimated 6 grants here by analogy to `grafana`
("same broad set... shared module lineage"). The analogy does not hold: this
module has no hardcoded policies, and its only real-world grant is the KMS
statement. Actual is **1 statement per cluster per service account** - the
largest single correction found in its batch. Do not size the shared policy
object's headroom off the original estimate.

## Unresolved fork you are inheriting

AWS grants this workload app-level KMS encrypt/decrypt. **GCP's port of the same
module grants nothing at all**, routing encryption through the database layer's
CMEK instead. Neither is obviously the target, and OCI Database with PostgreSQL
supports no customer-managed key at all, which weakens the case for GCP's
choice. Leaving `kms_key_id` null adopts GCP's shape; setting it adopts AWS's.
Check sheet section 8 item 2, oracle gate **not yet consulted**.

## What is deliberately not here

| AWS surface | Why it is absent |
|---|---|
| `role_name`, `role_path`, `max_session_duration`, `force_detach_policies` | STS/role plumbing. There is no role. |
| `assume_role_principals` | Verdict NONE - no assumable object exists. |
| `aws_managed_policy_names` | Verdict NONE - OCI publishes suggested statement *text*, not attachable named objects. |
| `customer_managed_policy_arns` | Folded into `extra_statements` (SUBSTITUTE - `shared-policy` becomes a text factory). |
| `host_domains` | A DNS/routing concern that was already a pure passthrough with no infrastructure effect. |
| `database_create_global_cluster` and siblings | No global-cluster object on OCI. Cross-region DR is `enable_warm_standby` + `primary_db_system_id`, exposed under their real names. |
