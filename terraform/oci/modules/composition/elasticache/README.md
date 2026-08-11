# elasticache (OCI) → OCI Cache with Redis

OCI equivalent of `terraform/aws/modules/composition/elasticache`. Uses `oci_redis_redis_cluster` (OCI Cache with
Redis). No verified registry module exists for this service - raw `oci` provider resource.

## Gaps vs. ElastiCache

- **Global Replication Group** (cross-region) has no OCI equivalent - omitted.
- **Snapshot import/export to S3** has no equivalent; use `oci_redis_oci_cache_config_set` + native backup instead.
- AWS `cluster_mode` (`enabled`/`disabled`) maps to OCI `cluster_mode` (`SHARDED`/`NONSHARDED`).
