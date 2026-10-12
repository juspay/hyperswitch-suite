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

- **Identity.** No dynamic group or IAM policy; owned by the OCI identity model.
- **Security rules.** Both NSGs are created empty on purpose.
- **NLB backend fallback.** If instance-pool NLB backend registration is not
  accepted, scripted per-instance registration is required and is not written
  here.

## Validation

`terraform validate` and `terraform fmt` pass.