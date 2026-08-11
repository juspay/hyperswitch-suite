# database (OCI) → OCI Database with PostgreSQL

OCI equivalent of `terraform/aws/modules/composition/database` (Aurora PostgreSQL). Uses `oci_psql_db_system`
(OCI Database with PostgreSQL — Oracle's managed PostgreSQL service). No verified registry module exists for this
service, so this is a plain `oci` provider resource.

## Gaps vs. Aurora

- **Global Database** (cross-region read replicas via `aws_rds_global_cluster`) has no OCI PostgreSQL equivalent — omitted.
- **Serverless v2 autoscaling** has no equivalent — OCI PostgreSQL instance shapes are fixed-size (flex OCPU/memory, resized via `instance_ocpu_count`/`instance_memory_size_in_gbs`, not autoscaled).
- **S3 import / point-in-time restore from S3** has no equivalent.
- Point-in-time recovery is supported via `management_policy.pitr_policy` (not wired up here; add if needed).

## Credentials

The AWS module supports both a literal `master_password` and `manage_master_user_password` (AWS Secrets Manager
auto-generated password). OCI's `credentials.password_details` only accepts a **Vault secret reference**
(`password_type = "VAULT_SECRET"`) — plaintext is supported too (`PLAIN_TEXT`) but a Vault secret is used here to
match the AWS module's secrets-manager-managed default.
