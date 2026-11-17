# squid-proxy (OCI)

The egress forward-proxy tier: an autoscaled fleet of VMs running Squid behind
an internal OCI Network Load Balancer, through which every outbound call from
the platform is forced so it can be domain-allowlisted and logged.

## Resources

| File | Resources |
|---|---|
| `network.tf` | `oci_core_network_security_group` x2 (instances, NLB) |
| `compute.tf` | `tls_private_key`, `oci_vault_secret`, `oci_core_instance_configuration`, `oci_core_instance_pool`, `oci_autoscaling_auto_scaling_configuration` |
| `loadbalancer.tf` | `oci_network_load_balancer_network_load_balancer`, backend set, listener |
| `storage.tf` | `oci_objectstorage_bucket` x2, `oci_objectstorage_object` (squid.conf, allowedlist.txt, extras), `oci_objectstorage_object_lifecycle_policy` |

## The image contract

The module ships `allowedlist.txt` to Object Storage. The timer that fetches it
and runs `squid -k reconfigure` lives in the **image**, not here — without it
the allowlist object is inert. `var.image_id` says so at the point of use.

## Deliberately not implemented

- **Security rules.** Both NSGs are created empty on purpose.
- **NLB backend registration.** Confirmed impossible (2026-11-17): the
  instance-pool service rejects an NLB OCID in
  `oci_core_instance_pool.load_balancers` with 404-NotAuthorizedOrNotFound, so
  `var.attach_pool_to_nlb` defaults to false and backend membership is
  maintained by scripted per-instance `oci nlb backend create` registration
  outside this module.

Identity is not on this list: `identity.tf` has owned the fleet's
instance-principal identity (tag namespace, dynamic group, read-objects
policy) since 2026-09-10.

## Validation

`terraform validate` and `terraform fmt` pass.