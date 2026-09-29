# Invokr application resources

Creates the optional AWS resources used by an Invokr deployment: Aurora PostgreSQL, a shared KMS key, an optional Secrets Manager bootstrap-configuration container, and an IAM/IRSA role for Invokr's KMS-enabled image.

The module does not deploy Kubernetes resources, populate secret values, run SQL migrations, or install PostgreSQL extensions.

## KMS-enabled Invokr mode

Invokr's KMS-enabled image calls AWS KMS directly at startup. Set both Helm values:

```yaml
apiConfigs:
  auth_mode: oidc
  oidc_issuer_url: https://idp.example.com/
  oidc_client_id: invokr
  oidc_redirect_host: https://invokr.example.com
  api_token_prefix: ivk_

configs:
  kms_enabled: true

kms:
  enabled: true

existingSecret: invokr

extraEnv:
  - name: AWS_REGION
    value: ap-south-1

serviceAccount:
  create: true
  name: invokr
  annotations:
    eks.amazonaws.com/role-arn: <module.role_arn>
```

The Kubernetes Secret referenced by `existingSecret` must contain these required keys:

```text
INVOKR_DATABASE_URL
INVOKR_ENCRYPTION_KEY
```

Authentication may additionally require these sensitive keys:

```text
INVOKR_OIDC_CLIENT_SECRET
INVOKR_API_STATIC_TOKENS
```

`INVOKR_OIDC_CLIENT_SECRET` is conditional because some OIDC providers use a public client. `INVOKR_API_STATIC_TOKENS` is required when `apiConfigs.api_token_prefix` is configured. In KMS mode, these values and both required values must be base64-encoded AWS KMS ciphertext blobs. Invokr decrypts them in memory using the IRSA role. The module grants only `kms:Decrypt` and `kms:DescribeKey`; it does not grant Invokr direct Secrets Manager access.

`INVOKR_API_KEY` is the deprecated pre-OIDC shared key. New deployments should not configure it. It exists only for migrating older callers. If it is temporarily retained in KMS mode, its value must also be a base64-encoded AWS KMS ciphertext blob.

After KMS decryption, a static-token value has this JSON shape:

```json
[
  {
    "token": "<high-entropy-token>",
    "principal": "recon-service"
  }
]
```

Machines authenticate with the configured prefix followed by the token:

```http
Authorization: Bearer ivk_<high-entropy-token>
```

The application secret resource is optional and is only an empty bootstrap-configuration container for External Secrets or another delivery process. Populate its KMS ciphertext strings using a process outside Terraform so credentials do not enter Terraform state. External Secrets Operator can then copy the ciphertext strings into the Kubernetes Secret unchanged. Invokr never reads AWS Secrets Manager directly.

No Secrets Manager resource is required when encrypted values are delivered directly as Kubernetes Secrets. This container does not hold Invokr endpoint or reconciliation credentials; those remain encrypted in Invokr's PostgreSQL database.

## Example

```hcl
module "invokr" {
  source = "../../modules/application-resources/invokr"

  environment  = "sandbox"
  region       = "ap-south-1"
  project_name = "hyperswitch"
  app_name     = "invokr"

  create_database = true
  database_config = {
    vpc_id                      = "vpc-..."
    subnet_ids                  = ["subnet-a", "subnet-b"]
    database_name               = "invokr_db"
    engine_version              = "17.9"
    master_username             = "invokr_admin"
    manage_master_user_password = true

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

    cluster_instances = {
      primary = {
        instance_class    = "db.t4g.medium"
        availability_zone = "ap-south-1a"
      }
    }
  }

  kms = {
    create              = true
    enable_key_rotation = true
    aliases             = ["alias/sandbox-hyperswitch-invokr"]
  }

  # Optional: create an empty container for External Secrets to read from.
  # Omit these settings when ciphertext is delivered directly to Kubernetes.
  create_application_secret = true
  application_secret_name   = "sandbox/invokr"

  create_iam_role                  = true
  enable_application_kms_decryption = true
  cluster_service_accounts = {
    sandbox-eks = {
      oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.ap-south-1.amazonaws.com/id/EXAMPLE"
      service_accounts = [
        {
          namespace = "invokr"
          name      = "invokr"
        }
      ]
    }
  }
}
```

The account ID and ARNs above are placeholders supplied by the caller; the module contains no environment-specific identifiers.

## PostgreSQL and migrations

The module treats `pg_cron` configuration as an invariant when it creates the database. Provide either:

- `db_cluster_parameter_group_name` referencing an existing parameter group already configured with `shared_preload_libraries` containing `pg_cron` and `cron.database_name` equal to `database_name`; or
- `create_custom_parameter_group = true` with those two parameter values. The module validates both values for a custom group.

Loading the library does not install the extension. After provisioning, apply Invokr's SQL migrations using an operational migration process. Invokr's migration includes:

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

Terraform intentionally does not use a PostgreSQL provider, create database users or grants, or execute migrations.

Database credential management follows the shared database-module interface. Prefer `manage_master_user_password = true` so RDS manages the password in Secrets Manager; `master_password` and `master_password_secretsmanager_secret_id` are also available when required. Supplying or reading a password through Terraform can place it in Terraform state.

When RDS manages the password, use `database_master_user_secret_arn` and `database_endpoint` outside this module to construct the database URL, KMS-encrypt it, and populate the application secret.

## Existing resources

Use an existing KMS key instead of creating one:

```hcl
kms = {
  key_arn = "arn:aws:kms:ap-south-1:123456789012:key/example"
}
```

When application-side KMS decryption is enabled with an existing key, the caller must ensure that key's resource policy authorizes the generated Invokr role. This module cannot modify an externally owned key policy.

Use an existing application secret instead of creating one:

```hcl
create_application_secret       = false
existing_application_secret_arn = "arn:aws:secretsmanager:ap-south-1:123456789012:secret:sandbox/invokr-example"
```

## Security-group integration

`database_security_group_id` is the stable output for live infrastructure that creates database ingress rules. The database composition creates the security group but this module does not add environment-specific ingress sources.

## Non-goals

This module does not:

- create a secret version or manage any secret value;
- require a Secrets Manager resource when bootstrap ciphertext is delivered directly as a Kubernetes Secret;
- store Invokr endpoint or reconciliation credentials in Secrets Manager;
- deploy External Secrets Operator, `ExternalSecret`, Helm, ArgoCD, or other Kubernetes resources;
- create namespaces, public ingress, dashboards, or Pomerium configuration;
- install `pg_cron` or run Invokr migrations;
- create PostgreSQL users or grants.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.31 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.66.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_database"></a> [database](#module\_database) | git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/database | database-v0.1.8 |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-aws-modules/kms/aws | 4.2.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.kms_decrypt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.customer_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_secretsmanager_secret.application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [terraform_data.application_secret_validation](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.database_validation](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_kms_key.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.existing_application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_assume_role_statements"></a> [additional\_assume\_role\_statements](#input\_additional\_assume\_role\_statements) | Additional IAM trust-policy statements | `list(any)` | `[]` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Application name used for resource naming and tagging | `string` | `"invokr"` | no |
| <a name="input_application_secret_description"></a> [application\_secret\_description](#input\_application\_secret\_description) | Description for the application secret | `string` | `null` | no |
| <a name="input_application_secret_kms_key_id"></a> [application\_secret\_kms\_key\_id](#input\_application\_secret\_kms\_key\_id) | KMS key for the application secret. Defaults to the effective module KMS key | `string` | `null` | no |
| <a name="input_application_secret_name"></a> [application\_secret\_name](#input\_application\_secret\_name) | Name of the application secret to create | `string` | `null` | no |
| <a name="input_application_secret_recovery_window_in_days"></a> [application\_secret\_recovery\_window\_in\_days](#input\_application\_secret\_recovery\_window\_in\_days) | Number of days Secrets Manager waits before deleting the application secret | `number` | `7` | no |
| <a name="input_application_secret_tags"></a> [application\_secret\_tags](#input\_application\_secret\_tags) | Additional tags applied to the application secret | `map(string)` | `{}` | no |
| <a name="input_assume_role_principals"></a> [assume\_role\_principals](#input\_assume\_role\_principals) | AWS principal ARNs allowed to assume the role | `list(string)` | `[]` | no |
| <a name="input_aws_managed_policy_names"></a> [aws\_managed\_policy\_names](#input\_aws\_managed\_policy\_names) | AWS-managed policy names to attach to the role | `list(string)` | `[]` | no |
| <a name="input_cluster_service_accounts"></a> [cluster\_service\_accounts](#input\_cluster\_service\_accounts) | Map of EKS cluster names to OIDC providers and Kubernetes service accounts allowed to assume the role | <pre>map(object({<br/>    oidc_provider_arn = string<br/>    service_accounts = list(object({<br/>      namespace = string<br/>      name      = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_create_application_secret"></a> [create\_application\_secret](#input\_create\_application\_secret) | Optional bootstrap-configuration container used by External Secrets or another delivery process. Invokr does not read AWS Secrets Manager directly | `bool` | `false` | no |
| <a name="input_create_database"></a> [create\_database](#input\_create\_database) | Whether to create an Aurora PostgreSQL database for Invokr | `bool` | `false` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Whether to create an IAM role for the Invokr Kubernetes service account | `bool` | `false` | no |
| <a name="input_customer_managed_policy_arns"></a> [customer\_managed\_policy\_arns](#input\_customer\_managed\_policy\_arns) | Customer-managed policy ARNs to attach to the role | `list(string)` | `[]` | no |
| <a name="input_database_config"></a> [database\_config](#input\_database\_config) | Aurora PostgreSQL configuration. Required when create\_database is true. An existing db\_cluster\_parameter\_group\_name must already load pg\_cron and set cron.database\_name to database\_name | <pre>object({<br/>    vpc_id                                    = string<br/>    subnet_ids                                = list(string)<br/>    cluster_identifier                        = optional(string)<br/>    cluster_identifier_prefix                 = optional(string)<br/>    database_name                             = optional(string)<br/>    engine                                    = optional(string, "aurora-postgresql")<br/>    engine_version                            = optional(string)<br/>    engine_mode                               = optional(string, "provisioned")<br/>    engine_lifecycle_support                  = optional(string, "open-source-rds-extended-support")<br/>    cluster_scalability_type                  = optional(string)<br/>    master_username                           = optional(string)<br/>    master_password                           = optional(string)<br/>    manage_master_user_password               = optional(bool)<br/>    master_password_secretsmanager_secret_id  = optional(string)<br/>    master_password_secretsmanager_secret_key = optional(string)<br/>    master_user_secret_kms_key_id             = optional(string)<br/>    db_cluster_instance_class                 = optional(string)<br/>    availability_zones                        = optional(list(string))<br/>    allocated_storage                         = optional(number)<br/>    storage_type                              = optional(string)<br/>    iops                                      = optional(number)<br/>    network_type                              = optional(string, "IPV4")<br/>    port                                      = optional(number, 5432)<br/>    create_db_subnet_group                    = optional(bool, true)<br/>    db_subnet_group_name                      = optional(string)<br/>    vpc_security_group_ids                    = optional(list(string), [])<br/>    db_cluster_parameter_group_name           = optional(string)<br/>    db_instance_parameter_group_name          = optional(string)<br/>    backup_retention_period                   = optional(number, 7)<br/>    preferred_backup_window                   = optional(string)<br/>    preferred_maintenance_window              = optional(string)<br/>    skip_final_snapshot                       = optional(bool, false)<br/>    final_snapshot_identifier                 = optional(string)<br/>    snapshot_identifier                       = optional(string)<br/>    copy_tags_to_snapshot                     = optional(bool, true)<br/>    storage_encrypted                         = optional(bool, true)<br/>    deletion_protection                       = optional(bool, false)<br/>    delete_automated_backups                  = optional(bool, true)<br/>    iam_database_authentication_enabled       = optional(bool, false)<br/>    iam_roles                                 = optional(list(string), [])<br/>    domain                                    = optional(string)<br/>    domain_iam_role_name                      = optional(string)<br/>    allow_major_version_upgrade               = optional(bool)<br/>    apply_immediately                         = optional(bool)<br/>    enabled_cloudwatch_logs_exports           = optional(list(string), ["postgresql"])<br/>    performance_insights_enabled              = optional(bool, false)<br/>    performance_insights_kms_key_id           = optional(string)<br/>    performance_insights_retention_period     = optional(number, 7)<br/>    monitoring_interval                       = optional(number, 0)<br/>    monitoring_role_arn                       = optional(string)<br/>    database_insights_mode                    = optional(string, "standard")<br/>    enable_http_endpoint                      = optional(bool, false)<br/>    enable_local_write_forwarding             = optional(bool)<br/>    replication_source_identifier             = optional(string)<br/>    source_region                             = optional(string)<br/>    backtrack_window                          = optional(number, 0)<br/>    ca_certificate_identifier                 = optional(string)<br/>    db_system_id                              = optional(string)<br/>    create_security_group                     = optional(bool, true)<br/>    security_group_name                       = optional(string)<br/>    security_group_description                = optional(string)<br/>    scaling_configuration                     = optional(any)<br/>    serverlessv2_scaling_configuration        = optional(any)<br/>    restore_to_point_in_time                  = optional(any)<br/>    s3_import                                 = optional(any)<br/>    create_global_cluster                     = optional(bool, false)<br/>    global_cluster_identifier                 = optional(string)<br/>    global_deletion_protection                = optional(bool, true)<br/>    enable_global_write_forwarding            = optional(bool, false)<br/>    use_existing_as_global_primary            = optional(bool, false)<br/>    source_db_cluster_identifier              = optional(string)<br/>    create_custom_parameter_group             = optional(bool, false)<br/>    custom_parameter_group_name               = optional(string)<br/>    custom_parameter_group_family             = optional(string)<br/>    custom_parameter_group_description        = optional(string)<br/>    custom_parameter_group_parameters = optional(list(object({<br/>      name         = string<br/>      value        = string<br/>      apply_method = optional(string, "immediate")<br/>    })), [])<br/>    cluster_instances = optional(map(object({<br/>      identifier                            = optional(string)<br/>      identifier_prefix                     = optional(string)<br/>      instance_class                        = string<br/>      engine                                = optional(string)<br/>      engine_version                        = optional(string)<br/>      publicly_accessible                   = optional(bool, false)<br/>      db_parameter_group_name               = optional(string)<br/>      apply_immediately                     = optional(bool)<br/>      monitoring_role_arn                   = optional(string)<br/>      monitoring_interval                   = optional(number, 0)<br/>      promotion_tier                        = optional(number, 0)<br/>      availability_zone                     = optional(string)<br/>      preferred_backup_window               = optional(string)<br/>      preferred_maintenance_window          = optional(string)<br/>      auto_minor_version_upgrade            = optional(bool, true)<br/>      performance_insights_enabled          = optional(bool)<br/>      performance_insights_kms_key_id       = optional(string)<br/>      performance_insights_retention_period = optional(number, 7)<br/>      copy_tags_to_snapshot                 = optional(bool, false)<br/>      ca_cert_identifier                    = optional(string)<br/>      custom_iam_instance_profile           = optional(string)<br/>      force_destroy                         = optional(bool, false)<br/>      tags                                  = optional(map(string), {})<br/>    })), {})<br/>    tags = optional(map(string), {})<br/>  })</pre> | `null` | no |
| <a name="input_enable_application_kms_decryption"></a> [enable\_application\_kms\_decryption](#input\_enable\_application\_kms\_decryption) | Attach kms:Decrypt and kms:DescribeKey permissions for Invokr's KMS-enabled image | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (for example, sandbox, dev, or prod) | `string` | n/a | yes |
| <a name="input_existing_application_secret_arn"></a> [existing\_application\_secret\_arn](#input\_existing\_application\_secret\_arn) | ARN of an existing Invokr application secret. Mutually exclusive with create\_application\_secret | `string` | `null` | no |
| <a name="input_force_detach_policies"></a> [force\_detach\_policies](#input\_force\_detach\_policies) | Whether to detach policies before destroying the IAM role | `bool` | `true` | no |
| <a name="input_inline_policies"></a> [inline\_policies](#input\_inline\_policies) | Additional inline IAM policies keyed by policy name | `map(string)` | `{}` | no |
| <a name="input_kms"></a> [kms](#input\_kms) | Shared KMS key configuration. Create a key or provide an existing key ARN | <pre>object({<br/>    create                             = optional(bool, false)<br/>    key_arn                            = optional(string)<br/>    description                        = optional(string)<br/>    multi_region                       = optional(bool, false)<br/>    deletion_window_in_days            = optional(number, 30)<br/>    enable_key_rotation                = optional(bool, true)<br/>    rotation_period_in_days            = optional(number)<br/>    bypass_policy_lockout_safety_check = optional(bool)<br/>    aliases                            = optional(list(string), [])<br/>    aliases_use_name_prefix            = optional(bool, false)<br/>    key_administrators                 = optional(list(string), [])<br/>    key_users                          = optional(list(string), [])<br/>    key_service_users                  = optional(list(string), [])<br/>    key_owners                         = optional(list(string), [])<br/>    source_policy_documents            = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum IAM role session duration in seconds | `number` | `3600` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region. Defaults to the provider region when null | `string` | `null` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Custom IAM role description | `string` | `null` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Custom IAM role name | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | IAM role path | `string` | `"/"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | AWS account ID |
| <a name="output_application_secret_arn"></a> [application\_secret\_arn](#output\_application\_secret\_arn) | ARN of the created or existing application secret |
| <a name="output_application_secret_name"></a> [application\_secret\_name](#output\_application\_secret\_name) | Name of the created or existing application secret |
| <a name="output_database_cluster_arn"></a> [database\_cluster\_arn](#output\_database\_cluster\_arn) | Aurora cluster ARN |
| <a name="output_database_cluster_id"></a> [database\_cluster\_id](#output\_database\_cluster\_id) | Aurora cluster ID |
| <a name="output_database_custom_parameter_group_name"></a> [database\_custom\_parameter\_group\_name](#output\_database\_custom\_parameter\_group\_name) | Name of the custom Aurora cluster parameter group |
| <a name="output_database_enabled"></a> [database\_enabled](#output\_database\_enabled) | Whether the database is created |
| <a name="output_database_endpoint"></a> [database\_endpoint](#output\_database\_endpoint) | Aurora writer endpoint |
| <a name="output_database_master_user_secret_arn"></a> [database\_master\_user\_secret\_arn](#output\_database\_master\_user\_secret\_arn) | ARN of the RDS-managed master-user secret |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Database name |
| <a name="output_database_port"></a> [database\_port](#output\_database\_port) | Database port |
| <a name="output_database_reader_endpoint"></a> [database\_reader\_endpoint](#output\_database\_reader\_endpoint) | Aurora reader endpoint |
| <a name="output_database_security_group_id"></a> [database\_security\_group\_id](#output\_database\_security\_group\_id) | ID of the dedicated database security group. Use this output for ingress-rule dependencies |
| <a name="output_db_global_cluster_arn"></a> [db\_global\_cluster\_arn](#output\_db\_global\_cluster\_arn) | Aurora global cluster ARN |
| <a name="output_db_global_cluster_id"></a> [db\_global\_cluster\_id](#output\_db\_global\_cluster\_id) | Aurora global cluster ID |
| <a name="output_iam_role_id"></a> [iam\_role\_id](#output\_iam\_role\_id) | ID of the Invokr IAM/IRSA role |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the Invokr IAM/IRSA role |
| <a name="output_kms_aliases"></a> [kms\_aliases](#output\_kms\_aliases) | Aliases created by this module; empty for an existing key |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the created or existing KMS key |
| <a name="output_kms_key_enabled"></a> [kms\_key\_enabled](#output\_kms\_key\_enabled) | Whether a created or existing KMS key is configured |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ID of the created or existing KMS key |
| <a name="output_region"></a> [region](#output\_region) | AWS region where resources are managed |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the Invokr IAM/IRSA role |
<!-- END_TF_DOCS -->
