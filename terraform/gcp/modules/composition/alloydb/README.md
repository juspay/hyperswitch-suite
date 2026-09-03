# composition/alloydb

AlloyDB for PostgreSQL - the production-grade GCP counterpart to
`composition/cloud-sql`, and the closest analogue of the AWS
`composition/database` (Aurora PostgreSQL) module.

## Cross-region disaster recovery

This is AlloyDB's counterpart of Aurora Global Database, and it follows the
same active/passive shape the AWS catalog drives off `values.is_passive`: one
live unit per region, the passive one pointed at the active one's output.

Leave `primary_cluster_name` unset - the default - and the module builds a
standalone `PRIMARY`. Set it and the module builds a `SECONDARY`: continuously
replicated from the primary, read-only until promoted.

```hcl
# terraform/gcp/live/dev/asia-south1/alloydb  (active)
inputs = {
  region     = "asia-south1"
  network_id = dependency.vpc.outputs.network_id
  # primary_cluster_name omitted -> PRIMARY
}

# terraform/gcp/live/dev/asia-south2/alloydb-dr  (passive)
dependency "primary_db" {
  config_path = "../../asia-south1/alloydb"
}

inputs = {
  region               = "asia-south2"
  network_id           = dependency.vpc.outputs.network_id
  allocated_ip_range   = "hyperswitch-dev-psa-range"   # same range, see below
  primary_cluster_name = dependency.primary_db.outputs.cluster_name

  primary_instance = {
    availability_type = "REGIONAL"
    cpu_count         = 2
  }
}
```

### What differs on a secondary

| | Primary | Secondary |
| --- | --- | --- |
| Initial user / generated password / Secret Manager | Created | Inherited from the primary - these inputs are inert, and the module raises an error rather than silently ignoring them |
| Read pools | Supported | **Not supported by AlloyDB** - `read_pool_instances` must be empty |
| Automated + continuous backup | Configured | Configured independently, per cluster - both stay active |
| Writes | Accepted | Rejected until promoted |

`cluster_type` is exposed as an output so you can assert which role a unit is
actually running in.

### Networking

No extra networking is needed for the second region. The Private Service
Access allocated range is a *global* address and the peering is per-network,
so the DR unit reuses the same `network_id` and `allocated_ip_range` as the
primary. If CMEK is enabled, each region needs its own key - KMS keys are
regional - which the module already handles by creating its keyring in
`var.region`.

### Runbook: switchover and promotion

Neither is a Terraform operation. This is the significant operational gap
versus Aurora Global Database, where failover is managed through the API.

**Planned switchover** (both regions healthy, no data loss):

1. Run the switchover outside Terraform:
   ```
   gcloud alloydb clusters switchover <SECONDARY_CLUSTER_ID> \
     --region=<SECONDARY_REGION> --project=<PROJECT_ID>
   ```
2. Reconcile state on both units: `terragrunt apply -refresh-only`
3. Move `primary_cluster_name` to the other unit - remove it from the newly
   promoted cluster's unit, add it to the demoted one - and apply.

**Unplanned promotion** (primary region lost):

1. Remove `primary_cluster_name` from the DR unit and apply. It becomes a
   standalone `PRIMARY` and starts accepting writes.
2. Replication is now broken, not just reversed. Re-establishing DR means
   recreating the old region's cluster as a new secondary pointing at the
   promoted one.

**Application cutover is not covered by either.** The app config references
the database by hardcoded private IP (see `deployment-configs/gcp/<env>/`),
so a promotion also requires updating those values to the promoted cluster's
IP and restarting the workloads. Worth resolving with a DNS name before
relying on this path in anger.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.23, < 8.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 7.46.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_alloydb"></a> [alloydb](#module\_alloydb) | GoogleCloudPlatform/alloy-db/google | ~> 8.0 |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-google-modules/kms/google | 4.1.2 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_secret_manager_secret.master_password](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_version.master_password](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [random_password.master](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allocated_ip_range"></a> [allocated\_ip\_range](#input\_allocated\_ip\_range) | Name (not CIDR) of the Private Service Access reserved IP range - composition/vpc-network exposes this as private\_service\_access\_range\_name | `string` | n/a | yes |
| <a name="input_automated_backup_enabled"></a> [automated\_backup\_enabled](#input\_automated\_backup\_enabled) | Whether to enable daily automated (snapshot) backups | `bool` | `true` | no |
| <a name="input_automated_backup_retention_count"></a> [automated\_backup\_retention\_count](#input\_automated\_backup\_retention\_count) | Number of automated daily backups to retain | `number` | `14` | no |
| <a name="input_automated_backup_start_hour"></a> [automated\_backup\_start\_hour](#input\_automated\_backup\_start\_hour) | UTC hour (0-23) the daily automated backup window starts | `number` | `2` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | AlloyDB cluster ID. Defaults to '<environment>-<project\_name>-alloydb' | `string` | `null` | no |
| <a name="input_continuous_backup_enabled"></a> [continuous\_backup\_enabled](#input\_continuous\_backup\_enabled) | Whether to enable continuous backup (AlloyDB's point-in-time recovery equivalent) | `bool` | `true` | no |
| <a name="input_continuous_backup_recovery_window_days"></a> [continuous\_backup\_recovery\_window\_days](#input\_continuous\_backup\_recovery\_window\_days) | Number of days of continuous backup / PITR window to retain | `number` | `14` | no |
| <a name="input_database_version"></a> [database\_version](#input\_database\_version) | PostgreSQL engine version | `string` | `"POSTGRES_15"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Whether to enable deletion protection on the cluster | `bool` | `true` | no |
| <a name="input_encryption_key_name"></a> [encryption\_key\_name](#input\_encryption\_key\_name) | Self-link of an existing KMS CryptoKey for cluster encryption. Takes precedence over var.kms.create | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_kms"></a> [kms](#input\_kms) | CMEK configuration. Set create=true to have this module create a KMS keyring/key for cluster encryption | <pre>object({<br/>    create          = optional(bool, false)<br/>    keyring_name    = optional(string)<br/>    key_name        = optional(string, "alloydb")<br/>    rotation_period = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | Password for the bootstrap admin user. Leave null to auto-generate a random one (AlloyDB has no built-in auto-generation like Cloud SQL - this module replicates it with its own random\_password resource) | `string` | `null` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Name of the cluster's bootstrap admin user | `string` | `"hyperswitch_admin"` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | Self-link/ID of the VPC network to attach the cluster to (requires Private Service Access to already be configured, see composition/vpc-network) | `string` | n/a | yes |
| <a name="input_primary_cluster_name"></a> [primary\_cluster\_name](#input\_primary\_cluster\_name) | Fully-qualified resource name of the primary cluster this one replicates<br/>from (the primary unit's `cluster_name` output, i.e.<br/>projects/<p>/locations/<r>/clusters/<id>). Leave null - the default - and<br/>this is a standalone PRIMARY cluster.<br/><br/>Set it and this becomes a cross-region SECONDARY: continuously replicated<br/>from the primary, read-only until promoted. This is AlloyDB's counterpart<br/>of the AWS module's Aurora Global Database support, and the same<br/>active/passive shape the AWS catalog drives off `values.is_passive` - one<br/>live unit per region, the passive one pointed at the active one's output.<br/><br/>A secondary inherits the primary's users, so master\_username /<br/>master\_password / secret\_manager do nothing here, and read pools cannot be<br/>created on a secondary cluster at all. Backups (automated and continuous)<br/>ARE configured independently per cluster and stay in effect.<br/><br/>Promotion and switchover are NOT Terraform operations - see this module's<br/>README for the runbook. Unlike Aurora, failing over means a `gcloud alloydb<br/>clusters switchover` call followed by `terraform apply -refresh-only` and<br/>moving this variable to the other unit. | `string` | `null` | no |
| <a name="input_primary_instance"></a> [primary\_instance](#input\_primary\_instance) | Configuration for the cluster's single primary instance. Every attribute is<br/>optional; instance\_id defaults to '<cluster\_id>-primary'.<br/><br/>  availability\_type - ZONAL (single zone, no standby - cheapest, dev/test<br/>                      only per Google's own guidance) or REGIONAL<br/>                      (active+standby across zones, automated failover).<br/>  cpu\_count         - vCPUs. Valid discrete values: 1, 2, 4, 8, 16, 32, 64,<br/>                      96, 128. 1 is C4A-only and region-limited, so 2 is the<br/>                      practical dev floor; use 8+ for real production load.<br/>  machine\_type      - Explicit machine type. cpu\_count is still sent<br/>                      alongside it, matching the upstream module's own<br/>                      behaviour (it always populates both).<br/>  gce\_zone          - Zone to pin to. Only honoured when availability\_type<br/>                      is ZONAL; upstream nulls it out on REGIONAL.<br/>  database\_flags    - Postgres flags - AlloyDB's equivalent of an RDS<br/>                      parameter group, e.g.<br/>                      { "alloydb.iam\_authentication" = "on" }.<br/>  ssl\_mode,         - Transport security, the equivalent of the AWS side's<br/>  require\_connectors  rds.force\_ssl parameter group entry.<br/>  query\_insights\_config - The equivalent of Performance Insights. | <pre>object({<br/>    instance_id               = optional(string)<br/>    display_name              = optional(string)<br/>    availability_type         = optional(string, "REGIONAL")<br/>    cpu_count                 = optional(number, 2)<br/>    machine_type              = optional(string)<br/>    gce_zone                  = optional(string)<br/>    database_flags            = optional(map(string))<br/>    labels                    = optional(map(string), {})<br/>    annotations               = optional(map(string))<br/>    ssl_mode                  = optional(string)<br/>    require_connectors        = optional(bool)<br/>    enable_public_ip          = optional(bool, false)<br/>    enable_outbound_public_ip = optional(bool, false)<br/>    cidr_range                = optional(list(string))<br/>    query_insights_config = optional(object({<br/>      query_string_length     = optional(number)<br/>      record_application_tags = optional(bool)<br/>      record_client_address   = optional(bool)<br/>      query_plans_per_minute  = optional(number)<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the cluster is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for labeling and naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_read_pool_instances"></a> [read\_pool\_instances](#input\_read\_pool\_instances) | Read pool instances to create under this cluster, keyed by name - the same<br/>map-of-objects shape the AWS module uses for cluster\_instances. The map key<br/>becomes the instance\_id unless one is set explicitly. Empty by default<br/>(single-instance deployment); populate for read scaling:<br/><br/>  read\_pool\_instances = {<br/>    read-1 = { node\_count = 2, cpu\_count = 4 }<br/>    analytics = {<br/>      node\_count     = 1<br/>      cpu\_count      = 8<br/>      database\_flags = { "google.columnar\_engine.enabled" = "on" }<br/>    }<br/>  }<br/><br/>A pool with node\_count = 1 is zonal and node\_count >= 2 is regional, so<br/>availability\_type and gce\_zone are not settable on read pools. Labels and<br/>annotations are inherited from primary\_instance - that is an upstream module<br/>constraint, not a choice made here. | <pre>map(object({<br/>    instance_id        = optional(string)<br/>    display_name       = optional(string)<br/>    node_count         = optional(number, 1)<br/>    cpu_count          = optional(number, 2)<br/>    machine_type       = optional(string)<br/>    database_flags     = optional(map(string))<br/>    ssl_mode           = optional(string)<br/>    require_connectors = optional(bool)<br/>    enable_public_ip   = optional(bool, false)<br/>    cidr_range         = optional(list(string))<br/>    query_insights_config = optional(object({<br/>      query_string_length     = optional(number)<br/>      record_application_tags = optional(bool)<br/>      record_client_address   = optional(bool)<br/>      query_plans_per_minute  = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | Region (AlloyDB 'location') for the cluster | `string` | n/a | yes |
| <a name="input_secret_manager"></a> [secret\_manager](#input\_secret\_manager) | Set create=true to have this module store the auto-generated master password in Secret Manager. Only takes effect when master\_password is left unset. | <pre>object({<br/>    create    = optional(bool, false)<br/>    secret_id = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | AlloyDB cluster ID |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Fully-qualified cluster resource name |
| <a name="output_cluster_type"></a> [cluster\_type](#output\_cluster\_type) | PRIMARY for a standalone cluster, SECONDARY when this one replicates from another region's cluster |
| <a name="output_generated_user_password"></a> [generated\_user\_password](#output\_generated\_user\_password) | The master password in effect (module-generated if master\_password was left unset) |
| <a name="output_instance_summary"></a> [instance\_summary](#output\_instance\_summary) | What was actually provisioned: the primary's sizing plus each read pool's node count and sizing |
| <a name="output_kms_key_name"></a> [kms\_key\_name](#output\_kms\_key\_name) | Self-link of the KMS key used for cluster encryption, if any |
| <a name="output_master_username"></a> [master\_username](#output\_master\_username) | Name of the bootstrap admin user |
| <a name="output_primary_instance_id"></a> [primary\_instance\_id](#output\_primary\_instance\_id) | ID of the primary instance |
| <a name="output_primary_instance_ip"></a> [primary\_instance\_ip](#output\_primary\_instance\_ip) | Private IP address of the primary instance - use this as the app's DB host |
| <a name="output_read_instance_ids"></a> [read\_instance\_ids](#output\_read\_instance\_ids) | IDs of the read pool instances, if any |
| <a name="output_read_instance_ids_by_name"></a> [read\_instance\_ids\_by\_name](#output\_read\_instance\_ids\_by\_name) | Read pool instance IDs keyed by instance\_id |
| <a name="output_read_instance_ips"></a> [read\_instance\_ips](#output\_read\_instance\_ips) | Private IP addresses of the read pool instances, if any |
| <a name="output_read_instance_ips_by_name"></a> [read\_instance\_ips\_by\_name](#output\_read\_instance\_ips\_by\_name) | Read pool private IP addresses keyed by instance\_id - use these as read-replica DB hosts |
| <a name="output_secret_manager_secret_id"></a> [secret\_manager\_secret\_id](#output\_secret\_manager\_secret\_id) | Secret ID of the Secret Manager secret holding the generated master password, if secret\_manager.create was set |
| <a name="output_secret_manager_secret_name"></a> [secret\_manager\_secret\_name](#output\_secret\_manager\_secret\_name) | Fully-qualified name (projects/.../secrets/...) of the Secret Manager secret, if created |
<!-- END_TF_DOCS -->