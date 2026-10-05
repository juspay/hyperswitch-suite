# Invokr unit

Reusable AWS application-resources unit, pinned to module `invokr-v0.1.0`.
Proposed unit release tag: `aws/unit/invokr-v0.1.0` (not created here).
After merge and tagging, a consuming hyperswitch-infra sandbox catalog stack can use:

```hcl
source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/invokr?ref=aws/unit/invokr-v0.1.0"
```

## Prerequisites

- Terragrunt with Stacks `values` support (suite CI uses 1.1.1), Terraform
  >= 1.5.0, and AWS provider >= 6.31, as required by the pinned module.
- A parent `root.hcl` exposing `locals.region`, `locals.environment.full`,
  and `locals.project_name`, and configuring the AWS provider and state backend.
- Applied EKS dependency exporting `cluster_name` and `oidc_provider_arn`.
  Dependency paths are relative to the generated unit directory.
- Helm/Kubernetes deployment managed separately: annotate the configured service
  account with the module's `role_arn`, enable Invokr's KMS mode, and supply
  `AWS_REGION`. Deliver KMS-encrypted bootstrap values to the Kubernetes Secret
  outside Terraform; see the [module documentation](../../../../../modules/application-resources/invokr/README.md).

## Supported Values

| Value | Default / behavior |
| --- | --- |
| `eks_config_path` | `../../eks-01` |
| `service_accounts` | List of `{ namespace, name }` subjects; overrides the single-account defaults below |
| `kubernetes_namespace`, `service_account_name` | Both `invokr`; no environment-specific subjects |
| `role_name` | Module-generated environment/project/application role name |
| `kms` | Released module's KMS object; dedicated key, rotation enabled, single-region by default |
| `kms.key_arn` | Existing key ARN; disables key creation automatically unless `kms.create` is explicitly set |
| `create_application_secret` | `false`; opt in to an empty Secrets Manager container |
| `existing_application_secret_arn` | `null`; references an existing container, mutually exclusive with creation |
| `application_secret_name` | `<environment>/<project>/invokr` when creating a container |
| `application_secret_description`, `application_secret_kms_key_id` | `null`; module description and effective KMS key |
| `application_secret_recovery_window_in_days` | `7` |
| `application_secret_tags`, `tags` | `{}`; additional secret tags / overrides to suite Project, Environment, ManagedBy, Region tags |
| `create_database` | `false`; no VPC dependency or database configuration needed by default |
| `vpc_config_path` | `../../../vpc-network`; used only when database creation is enabled |
| `database_config` | Required when creating a database; accepts the released module's database object except VPC/subnets, which always come from the dependency |

The unit always creates the application IRSA role and enables the module's
`kms:Decrypt` / `kms:DescribeKey` policy, scoped to the effective key ARN.
It attaches no additional IAM policies or AWS trust principals and grants no
Secrets Manager access. With an existing key, its owner must ensure the key
policy permits the generated role to decrypt. `kms.create = false` without an
existing key is invalid for this unit's KMS-enabled application role.

Secrets Manager is optional: creating a container does not create a secret
version or populate values. An external delivery process encrypts bootstrap
values with the effective KMS key and populates/copies them to Kubernetes;
External Secrets Operator needs its own separate permissions. No plaintext or
ciphertext secret values belong in unit values or Terraform state.

## Opt-In Database

Set `create_database = true` and supply `database_config.database_name`, engine
version, master username, and a non-empty `cluster_instances` map with an
explicit `instance_class` for every instance. There is no default database
sizing. The unit defaults to RDS-managed master credentials and deletion
protection; caller database settings can override those defaults. Supplying
passwords through Terraform may expose them in state.

Supply either an existing `db_cluster_parameter_group_name` already configured
for `pg_cron`, or a custom parameter group with a matching engine family and
both required parameters. The pinned module validates custom parameter values
and non-empty instance sizing; an existing group's actual settings must be
verified operationally. Example values:

```hcl
create_database = true
database_config = {
  database_name   = "invokr_db"
  engine_version  = "17.9"
  master_username = "invokr_admin"
  cluster_instances = {
    primary = { instance_class = "db.t4g.medium" }
  }
  create_custom_parameter_group = true
  custom_parameter_group_family = "aurora-postgresql17"
  custom_parameter_group_parameters = [
    {
      name         = "shared_preload_libraries"
      value        = "pg_stat_statements,pg_cron"
      apply_method = "pending-reboot"
    },
    {
      name         = "cron.database_name"
      value        = "invokr_db"
      apply_method = "pending-reboot"
    }
  ]
}
```

The VPC dependency must export `vpc_id` and `database_subnet_ids`. Configure
network ingress separately using `database_security_group_id`. Run Invokr SQL
migrations separately to install `pg_cron`; this unit runs no SQL and creates
no PostgreSQL users or grants. Existing databases are used through externally
delivered bootstrap configuration, not a database dependency.

## Region And Validation Limits

No `is_passive`, primary-unit dependency, automatic global database, or KMS
replica behavior is inferred. The released module supports `kms.multi_region`
for a primary key but does **not** expose `create_replica` or `primary_key_arn`.
Its database object exposes explicit global/replication settings; these require
caller design and are not an automatic passive-region deployment path.

Both dependencies use shallow mock/state merging and allow mocks only for
`validate` and `plan`, never `apply`. An apply requires real dependency outputs.

Run `terragrunt hcl format --check --diff --file terragrunt.hcl` for formatting
and HCL syntax. This does not evaluate Stacks values, resolve dependencies, or
validate Terraform resources. Full validation requires a generated consuming
stack with real root/values and initialized module/provider dependencies;
run Terragrunt/Terraform validation and review a plan there before applying.
