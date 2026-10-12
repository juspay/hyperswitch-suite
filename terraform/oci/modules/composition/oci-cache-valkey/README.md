# oci-cache-valkey

OCI Cache (Valkey) — the platform's shared in-memory cache / session store on
OCI.

## Resources

| Resource | Count | When |
|---|---|---|
| `oci_redis_redis_cluster.main` | 1 | always |
| `oci_redis_oci_cache_config_set.main` | 0-1 | `create_config_set` (default false) |
| `oci_redis_oci_cache_backup.main` | 0-1 | `create_backup` (default false) |
| `oci_redis_oci_cache_user.main` | 0-N | one per `cache_users` entry |
| `oci_redis_redis_cluster_attach_oci_cache_user.main` | 0-1 | any `cache_users` |

A default instantiation creates exactly **one** resource. The module creates no
subnet, VCN, NSG or security list; it places a cluster into the supplied
`compartment_id`, `subnet_id` and `nsg_ids`.

## Things that are not here, on purpose

- **No transit-encryption off-switch.** OCI Cache is TLS-only at the Terraform
  level. Confirm the Valkey client speaks TLS before pointing a workload at a
  cluster.
- **No at-rest encryption / CMEK argument.** OCI Cache exposes neither; at-rest
  behaviour is unverified.
- **No 2-shard topology.** OCI requires an odd shard count (3-99). Enforced by a
  `validation` block on `shard_count`; choose 3 shards or `NONSHARDED`.
- **No cross-region global replication.** No OCI primitive exists.
- **No maintenance window, automatic-failover toggle, notification/log hooks,
  or per-shard placement.** None are arguments on the OCI resource.

## Not a singleton

`name_suffix` lets a second unit instantiate the module again in the same
compartment — e.g. a shared cache plus dedicated caches off the same module.

## Validation

`terraform fmt -recursive`, `terraform init -backend=false` and
`terraform validate` are clean against `oracle/oci` v9.0.0.