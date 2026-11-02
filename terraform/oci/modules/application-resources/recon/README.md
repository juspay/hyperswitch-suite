# recon (OCI)

OCI port of `hyperswitch-infra:terraform/aws/modules/application-resources/recon`.
Three jobs in one Terraform state, as on AWS:

1. **Its own KMS key.** A vault + key (`kms.tf`, same shape as the hyperswitch
   module's), consumed by the service's `oci_kms` secrets manager through
   `kms_vault_crypto_endpoint` + `kms_key_id`. Recon does not borrow
   hyperswitch's key, because on AWS it does not either.

2. **Its own private bucket** (`object_storage.tf`), versioned, no public access.

3. **An identity contribution.** No role, no policy object: the AWS role's
   policies become statements in `policy_statements`, which the shared
   `oke-workload-identity` unit concatenates into the environment's one policy.

Plus an **optional dedicated PostgreSQL database**, nested rather than
depended-on, so it provisions in stack phase 3 alongside the app. Same as AWS.

## Statement budget: four

Per cluster per service account, with every feature on:

| AWS policy                     | OCI statement                                    |
| ------------------------------ | ------------------------------------------------ |
| `recon_kms`                    | `use keys` where `target.key.id` = recon's key   |
| `recon_s3`                     | `manage objects` where `target.bucket.name`      |
| `recon_secrets_manager`        | `read secret-bundles` + `read secrets`           |
| `recon_lambda_invoke`          | not ported (report generation moves to invokr)   |

## Object Storage authentication

The `manage objects` grant authorises the **workload identity**. Recon's
current `oci_object_storage` file-storage client goes through the
S3-compatible API with an OCI customer secret key instead, so until it moves to
workload identity the key's owning user also needs object access on this
bucket, granted outside this module.

## What is deliberately not here

- The IRSA role (`oidc_provider_arn`, `oidc_provider_id`,
  `additional_assume_role_statements`) - there is no role; identity is the four
  `request.principal.*` conditions on every statement.
- `kms.aliases`, `key_administrators`, `key_users` - OCI key access is
  statement-driven only.
- `s3_force_destroy` - `oci_objectstorage_bucket` has no such argument.
- `lambda_invoke_function_arns` - no FaaS on OCI for recon; see above.
- `database_config.create_global_cluster` and siblings - no global-cluster
  object on OCI. Cross-region DR is `enable_warm_standby` +
  `primary_db_system_id`.
