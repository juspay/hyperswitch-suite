# clickhouse (OCI)

OCI equivalent of `terraform/aws/modules/composition/clickhouse` (self-managed Clickhouse Keeper + Server nodes on
EC2, behind an internal ALB). Same pattern as `../cassandra`: `oracle-terraform-modules/compute-instance/oci`
(verified) for compute, plain `oci` provider resources for NSGs/IAM/Load Balancer.

## Mapping notes

| AWS | OCI |
|---|---|
| Internal `aws_lb` (ALB) + target groups + listener | `oci_load_balancer_load_balancer` (`is_private = true`) + backend set + backend + listener |
| EBS data + data2 volumes per node | `block_storage_sizes_in_gbs` (single list here; add a second size to the list to reproduce the AWS module's two-volume layout) |
| `time_sleep.wait_for_keeper` (180s) | Reproduce via `depends_on` plus your own wait/health-check step in the calling layer if Keeper needs to be fully quorate before Server nodes start — Terraform can enforce ordering (`depends_on = [module.keeper_nodes]`, already wired) but not a timed wait |
