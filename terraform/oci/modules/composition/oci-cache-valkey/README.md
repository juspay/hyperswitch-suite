# oci-cache-valkey

OCI Cache (Valkey) - the platform's shared in-memory cache / session store on
OCI. Port of `terraform/aws/modules/composition/elasticache`, with
`terraform/gcp/modules/composition/memorystore-valkey` as the intermediate
precedent.

Check sheet: `hyperswitch-infra:docs/multi-cloud-parity/oci/modules/elasticache.md`
(9 FULL / 5 PARTIAL / 1 SUBSTITUTE / 3 NONE).

## Strategy

`DIRECT-RESOURCE`. `search_modules` for OCI Redis/Cache returns nothing usable,
matching `provider-facts.md`'s finding that OCI has effectively two maintained
registry modules and neither is this one. Provider pinned `oracle/oci ~> 9.0`;
schema verified against v9.0.0.

## Resources

| Resource | Count | When |
|---|---|---|
| `oci_redis_redis_cluster.main` | 1 | always |
| `oci_redis_oci_cache_config_set.main` | 0-1 | `create_config_set` (default **false**) |
| `oci_redis_oci_cache_backup.main` | 0-1 | `create_backup` (default **false**) |
| `oci_redis_oci_cache_user.main` | 0-N | one per `cache_users` entry (default **{}**) |
| `oci_redis_redis_cluster_attach_oci_cache_user.main` | 0-1 | any `cache_users` |

A default instantiation creates exactly **one** resource.

This module creates no subnet, no VCN, no NSG and no security list. It takes
`compartment_id`, `subnet_id` and `nsg_ids` and places into them.

## Things that are not here, on purpose

Each of these is a recorded parity gap, commented at the point of divergence in
`variables.tf` / `main.tf`:

- **No `transit_encryption_enabled`.** OCI Cache is TLS-only with no
  Terraform-level off switch. The AWS units run `transit_encryption_enabled =
  false`; this module cannot replicate that, by necessity rather than by choice.
  Confirm the Valkey client speaks TLS, or raise an Oracle support request,
  before a workload is pointed at a cluster.
- **No `at_rest_encryption_enabled` / `kms_key_id`.** No argument exists and
  OCI's at-rest behaviour for this service is undocumented - unverified, not
  equivalent.
- **No 2-shard topology.** OCI requires an odd shard count, 3-99. The live AWS
  shared cache runs 2 shards. Enforced by a `validation` block on `shard_count`;
  the operator chooses 3 shards or `NONSHARDED` per instantiation.
- **No cross-region global replication.** No OCI primitive exists. The five AWS
  `global_replication_group_*` / `is_*_cluster` outputs are deliberately not
  emitted. Backup/export/re-import DR is out of scope here and blocked on the
  oracle gate.
- **No maintenance window, no automatic-failover toggle, no notification or
  log-delivery hooks, no per-shard AZ/slot placement.** None of these are
  arguments on the OCI resource.

## Not a singleton

`name_suffix` exists so a second catalog unit can instantiate this module again
in the same compartment - AWS runs a shared cache plus dedicated instances for
`ratelimiter` and `locker` off the same module.

## Validation status

`terraform fmt -recursive`, `terraform init -backend=false` and
`terraform validate` clean against `oracle/oci` v9.0.0. Not yet planned against
a live root.
