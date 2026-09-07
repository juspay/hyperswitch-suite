<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.23, < 8.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 7.45.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_database"></a> [database](#module\_database) | ../alloydb | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-google-modules/kms/google | 4.1.2 |
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | terraform-google-modules/kubernetes-engine/google//modules/workload-identity | 44.3.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_kms_crypto_key_iam_member.locker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_secret_manager_secret_iam_member.master_password](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_project_roles"></a> [additional\_project\_roles](#input\_additional\_project\_roles) | Project-level IAM roles to grant the locker's service account on top of the AlloyDB connectivity pair (roles/alloydb.client and roles/serviceusage.serviceUsageConsumer) this module always grants | `list(string)` | `[]` | no |
| <a name="input_annotate_k8s_sa"></a> [annotate\_k8s\_sa](#input\_annotate\_k8s\_sa) | Whether to annotate the Kubernetes service account with the Google service account email | `bool` | `true` | no |
| <a name="input_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#input\_cluster\_ca\_certificate) | GKE cluster CA certificate, base64-encoded - required to configure this module's kubernetes provider | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | GKE cluster API server endpoint (bare host:port or IP, no scheme) - required to configure this module's kubernetes provider | `string` | n/a | yes |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster the locker runs on | `string` | n/a | yes |
| <a name="input_create_database"></a> [create\_database](#input\_create\_database) | Whether to create the vault's dedicated AlloyDB cluster. Setting false leaves this module creating only the service account and its IAM, for callers pointing the vault at a database managed elsewhere | `bool` | `true` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Whether to create a dedicated KMS keyring and key for the vault's AlloyDB cluster. Ignored when encryption\_key\_name is set | `bool` | `true` | no |
| <a name="input_database_config"></a> [database\_config](#input\_database\_config) | Configuration for the vault's dedicated AlloyDB cluster (composition/alloydb).<br/>Same object shape as application-resources/grafana and<br/>application-resources/superposition use for their own dedicated clusters.<br/><br/>allocated\_ip\_range is REQUIRED whenever create\_database is true - AlloyDB<br/>attaches over Private Service Access and composition/alloydb takes the<br/>reserved range by name, not by CIDR (composition/vpc-network exposes it as<br/>private\_service\_access\_range\_name). It is typed optional purely so callers<br/>that set create\_database = false need not supply it: Terraform validates<br/>full object conformance regardless of the count-gated branch that reads it.<br/><br/>There is deliberately no database\_name attribute. The google provider<br/>ships no resource for an individual AlloyDB database (only<br/>alloydb\_cluster / \_instance / \_user / \_backup), so the cluster's bootstrap<br/>`postgres` database is what exists after apply and creating the vault's<br/>own logical database is a SQL-level step.<br/><br/>secret\_manager defaults to { create = true } here, unlike<br/>composition/alloydb's own default of null: a pod has no instance-metadata<br/>channel to receive a module-generated password through, so Secret Manager<br/>is the only delivery path. Leave master\_password unset to use it. | <pre>object({<br/>    network_id          = string<br/>    allocated_ip_range  = optional(string)<br/>    cluster_id          = optional(string)<br/>    database_version    = optional(string)<br/>    availability_type   = optional(string)<br/>    cpu_count           = optional(number)<br/>    machine_type        = optional(string)<br/>    database_flags      = optional(map(string))<br/>    deletion_protection = optional(bool)<br/>    master_username     = optional(string)<br/>    master_password     = optional(string)<br/>    secret_manager = optional(object({<br/>      create    = optional(bool, true)<br/>      secret_id = optional(string)<br/>    }))<br/>  })</pre> | <pre>{<br/>  "network_id": null<br/>}</pre> | no |
| <a name="input_encryption_key_name"></a> [encryption\_key\_name](#input\_encryption\_key\_name) | Self-link of an existing KMS CryptoKey to encrypt the vault's cluster with. Takes precedence over create\_kms\_key | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_grant_kms_access"></a> [grant\_kms\_access](#input\_grant\_kms\_access) | Whether to grant the locker's service account cryptoKeyEncrypterDecrypter on the CMEK key, for application-level card encryption. Off by default - the key's purpose is encrypting the AlloyDB cluster, and the vault normally manages its own data-encryption keys internally | `bool` | `false` | no |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace the locker workload runs in | `string` | `"locker"` | no |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Kubernetes service account name used by the locker workload | `string` | `"locker"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Name of the created key inside the keyring | `string` | `"locker"` | no |
| <a name="input_kms_keyring_name"></a> [kms\_keyring\_name](#input\_kms\_keyring\_name) | Name of the created keyring. Defaults to '<environment>-<project\_name>-locker-keyring' | `string` | `null` | no |
| <a name="input_kms_prevent_destroy"></a> [kms\_prevent\_destroy](#input\_kms\_prevent\_destroy) | Whether to protect the created key from destruction. Leave true outside throwaway environments - AlloyDB backups are encrypted under this key and become unreadable without it | `bool` | `true` | no |
| <a name="input_kms_protection_level"></a> [kms\_protection\_level](#input\_kms\_protection\_level) | Protection level for the created key: SOFTWARE or HSM. HSM is the stricter choice for a PCI-DSS-scoped vault and costs more per key version | `string` | `"SOFTWARE"` | no |
| <a name="input_kms_rotation_period"></a> [kms\_rotation\_period](#input\_kms\_rotation\_period) | Rotation period for the created key, in seconds with an 's' suffix. Defaults to 90 days | `string` | `"7776000s"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where resources are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for the AlloyDB cluster and the KMS keyring | `string` | n/a | yes |
| <a name="input_use_existing_k8s_sa"></a> [use\_existing\_k8s\_sa](#input\_use\_existing\_k8s\_sa) | Whether the Kubernetes service account already exists (typically created by the locker's own Helm chart). Set true to bind Workload Identity to it instead of having Terraform create it - creating an SA the chart also owns collides on apply | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_database_cluster_id"></a> [database\_cluster\_id](#output\_database\_cluster\_id) | AlloyDB cluster ID of the vault's cluster, if created |
| <a name="output_database_cluster_name"></a> [database\_cluster\_name](#output\_database\_cluster\_name) | Fully-qualified resource name of the vault's AlloyDB cluster, if created |
| <a name="output_database_host"></a> [database\_host](#output\_database\_host) | Private IP of the vault cluster's primary instance - the host the locker pod connects to |
| <a name="output_database_port"></a> [database\_port](#output\_database\_port) | PostgreSQL port for the vault cluster. Fixed at 5432; exposed so callers templating a connection string do not hardcode it |
| <a name="output_granted_project_roles"></a> [granted\_project\_roles](#output\_granted\_project\_roles) | Project-level IAM roles granted to the locker's service account |
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Bound Kubernetes service account name - set the locker's pod spec serviceAccountName to this |
| <a name="output_k8s_service_account_namespace"></a> [k8s\_service\_account\_namespace](#output\_k8s\_service\_account\_namespace) | Namespace of the bound Kubernetes service account |
| <a name="output_kms_key_name"></a> [kms\_key\_name](#output\_kms\_key\_name) | Self-link of the KMS key encrypting the vault's cluster, whether created here or supplied via encryption\_key\_name |
| <a name="output_kms_keyring_name"></a> [kms\_keyring\_name](#output\_kms\_keyring\_name) | Name of the created keyring, if this module created one |
| <a name="output_master_password_secret_id"></a> [master\_password\_secret\_id](#output\_master\_password\_secret\_id) | Secret ID of the Secret Manager secret holding the generated master password, if one was created. This is what the locker's service account is granted accessor on |
| <a name="output_master_password_secret_name"></a> [master\_password\_secret\_name](#output\_master\_password\_secret\_name) | Fully-qualified name (projects/.../secrets/...) of the master password secret, if created - the reference to put in the locker's ExternalSecret or CSI SecretProviderClass |
| <a name="output_master_username"></a> [master\_username](#output\_master\_username) | Bootstrap admin username on the vault's cluster |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the locker's Google service account - the identity the GKE workload assumes via Workload Identity |
| <a name="output_service_account_name"></a> [service\_account\_name](#output\_service\_account\_name) | Fully qualified name of the locker's Google service account |
<!-- END_TF_DOCS -->
