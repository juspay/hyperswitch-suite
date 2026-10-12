# squid-proxy (OCI)

The egress forward-proxy tier: an autoscaled fleet of VMs running Squid behind
an internal OCI Network Load Balancer, through which every outbound call from
the platform is forced so it can be domain-allowlisted and logged. Port of
`terraform/aws/modules/composition/squid-proxy/`; the GCP port
(`terraform/gcp/modules/composition/squid-proxy/`) is the intermediate
precedent, and its whitelist-hot-reload design carries over unchanged.

Check sheet: `docs/multi-cloud-parity/oci/modules/squid-proxy.md`
(hyperswitch-infra).

## Provider verification

Every argument was read out of `oracle/oci` 9.0.0's own JSON schema
(`terraform providers schema -json`). DIRECT-RESOURCE throughout.

## Resource inventory

| File | Resources |
|---|---|
| `network.tf` | `oci_core_network_security_group` x2 (instances, NLB) |
| `compute.tf` | `tls_private_key`, `oci_vault_secret`, `oci_core_instance_configuration`, `oci_core_instance_pool`, `oci_autoscaling_auto_scaling_configuration` |
| `loadbalancer.tf` | `oci_network_load_balancer_network_load_balancer`, `_backend_set`, `_listener` |
| `storage.tf` | `oci_objectstorage_bucket` x2, `oci_objectstorage_object` (squid.conf, allowedlist.txt, extras), `oci_objectstorage_object_lifecycle_policy` |

## What is weaker than AWS, and where the comment lives

| Feature | Verdict | Where it is commented |
|---|---|---|
| TLS listener on the load balancer | **NONE** | `variables.tf` `tls_termination_mode`, `loadbalancer.tf` header |
| Autoscaling: threshold, not target-tracking | SUBSTITUTE | `variables.tf` `scaling_policies`, `locals.tf`, `compute.tf` |
| Spot/on-demand mixed pool | PARTIAL | `variables.tf` `is_preemptible`, `compute.tf` |
| Rolling instance refresh with checkpoints | PARTIAL | `variables.tf` `enable_pre_termination_hook`, `compute.tf` |
| Break-glass key: Vault + KMS key required | SUBSTITUTE | `variables.tf` `generate_ssh_key`, `compute.tf` |
| Security groups -> NSGs | SUBSTITUTE (decided) | `network.tf` |
| Pool-to-NLB backend registration unconfirmed | open question | `locals.tf` `pool_load_balancer_id`, `compute.tf` `load_balancers` |

`tls_termination_mode = "classic_lb"` is **rejected by validation**, not
half-implemented. Moving this fleet off the NLB onto the classic Load Balancer
trades away L3/L4 passthrough and source-IP preservation and is an unconsulted
oracle-gate decision (check sheet §8 item 1). Failing the plan with a pointer
to that decision is the honest behaviour; silently shipping the fork is not.

## The image contract

This module ships `allowedlist.txt` to Object Storage. The 15-minute timer that
fetches it and runs `squid -k reconfigure` lives in the **image**, not here.
Without that timer the allowlist object is inert and every allowlist change
silently does nothing. `var.image_id` says so at the point of use. On OCI only
the fetch tooling changes from GCP's proven version - `oci os object get` in
place of `gsutil cp`.

## Not yet implemented, deliberately

- **Identity.** No dynamic group or IAM policy; owned by
  `docs/multi-cloud-parity/oci/identity-model.md`.
- **Security rules.** Both NSGs are created empty on purpose.
- **NLB backend fallback.** If `oci_core_instance_pool.load_balancers` turns
  out not to accept an NLB backend set, scripted per-instance registration is
  required and is not written here.

## Validation reached

Rung 1 (`terraform validate`) and rung 2 (`terraform fmt`). Rungs 3-5 are the
orchestrator's; rung 6 is a human decision.
