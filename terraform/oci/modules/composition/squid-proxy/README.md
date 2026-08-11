# squid-proxy (OCI)

OCI equivalent of `terraform/aws/modules/composition/squid-proxy` (self-managed Squid instances behind an ASG +
NLB). Raw `oci` provider resources - no verified registry module exists for instance pools/configurations or
network load balancers.

## Mapping notes

| AWS | OCI |
|---|---|
| Launch Template | `oci_core_instance_configuration` |
| Auto Scaling Group | `oci_core_instance_pool` |
| NLB + target group + TCP/TLS listeners | `oci_network_load_balancer_network_load_balancer` + backend set + listener |
| ASG scaling policies / instance refresh / spot mix | Not modeled here — OCI Instance Pools support autoscaling via a separate `oci_autoscaling_auto_scaling_configuration` resource (not wired up in this module; add one pointed at `oci_core_instance_pool.squid.id` if dynamic scaling is needed, matching the AWS module's `scaling_policies`) |
| Single TLS listener (mTLS-capable ALB-style) | OCI Network Load Balancers are L4 (TCP/UDP) — TLS **termination** at the LB (the AWS module's `enable_tls_listener`) has no NLB equivalent; if TLS termination at the edge is required, front the instance pool with `oci_load_balancer_load_balancer` (L7, supports `ssl_configuration`) instead of the NLB used here |

This module places all instances in a single availability domain (`var.availability_domain`); add more entries to
`placement_configurations` for multi-AD spread.
