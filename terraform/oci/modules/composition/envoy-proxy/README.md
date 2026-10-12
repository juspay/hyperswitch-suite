# envoy-proxy (OCI)

The ingress reverse-proxy tier: an autoscaled fleet of VMs running Envoy behind
an OCI Load Balancer, terminating edge traffic before it reaches the internal
OKE/Istio ingress.

## Resources

| File | Resources |
|---|---|
| `network.tf` | `oci_core_network_security_group` x2 (instances, load balancer) |
| `compute.tf` | `tls_private_key`, `oci_vault_secret`, `oci_core_instance_configuration` (per deployment), `oci_core_instance_pool` (per deployment), `oci_autoscaling_auto_scaling_configuration` (per deployment) |
| `loadbalancer.tf` | `oci_load_balancer_load_balancer`, `oci_load_balancer_backend_set`, `oci_load_balancer_rule_set` (HTTPS redirect), `oci_load_balancer_load_balancer_routing_policy`, `oci_load_balancer_listener` x3 (http, https, mtls), `oci_waf_web_app_firewall` |
| `storage.tf` | `oci_objectstorage_bucket` x2, `oci_objectstorage_object` (per config file), `oci_objectstorage_object_lifecycle_policy` |

## Deliberately not implemented

- **Identity.** No dynamic group or IAM policy is created here; the fleet is
  granted verbs through a dynamic group owned elsewhere.
- **Security rules.** Both NSGs are created empty on purpose; they are populated
  by the security-last stack phase.
- **Certificate issuance.** `ssl_certificate_ids` is supplied as an input,
  never created.

## Validation

`terraform validate` and `terraform fmt` pass.