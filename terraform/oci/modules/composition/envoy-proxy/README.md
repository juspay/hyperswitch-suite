# envoy-proxy (OCI)

The ingress reverse-proxy tier: an autoscaled fleet of VMs running Envoy behind
an OCI Load Balancer, terminating edge traffic before it reaches the internal
OKE/Istio ingress. Port of `terraform/aws/modules/composition/envoy-proxy/`;
the GCP port (`terraform/gcp/modules/composition/envoy-proxy/`) is the
intermediate precedent.

Check sheet: `docs/multi-cloud-parity/oci/modules/envoy-proxy.md`
(hyperswitch-infra). Read it before changing anything here - the verdicts below
are its, not this README's.

## Provider verification

Every argument was read out of `oracle/oci` 9.0.0's own JSON schema
(`terraform providers schema -json`), not from memory or from the registry
website. Strategy is DIRECT-RESOURCE throughout: no OCI registry module exists
for compute, load balancing or WAF.

## Resource inventory

| File | Resources |
|---|---|
| `network.tf` | `oci_core_network_security_group` x2 (instances, load balancer) |
| `compute.tf` | `tls_private_key`, `oci_vault_secret`, `oci_core_instance_configuration` (per deployment), `oci_core_instance_pool` (per deployment), `oci_autoscaling_auto_scaling_configuration` (per deployment) |
| `loadbalancer.tf` | `oci_load_balancer_load_balancer`, `oci_load_balancer_backend_set` (1 or per deployment), `oci_load_balancer_rule_set` (HTTPS redirect), `oci_load_balancer_load_balancer_routing_policy`, `oci_load_balancer_listener` x3 (http, https, mtls), `oci_waf_web_app_firewall` |
| `storage.tf` | `oci_objectstorage_bucket` x2, `oci_objectstorage_object` (per config file), `oci_objectstorage_object_lifecycle_policy` |

## What is weaker than AWS, and where the comment lives

| Feature | Verdict | Where it is commented |
|---|---|---|
| Weighted multi-deployment traffic split | SUBSTITUTE | `variables.tf` `deployments`, `compute.tf` pool `load_balancers` block |
| HTTPS: no SNI multi-cert, no ACM-style public issuance | PARTIAL | `variables.tf` `ssl_certificate_ids`, `loadbalancer.tf` https listener |
| Routing rules: no source-IP dimension, grammar unconfirmed | PARTIAL | `variables.tf` `listener_rules`, `locals.tf` condition generator |
| Autoscaling: threshold, not target-tracking | SUBSTITUTE | `variables.tf` `scaling_policies`, `locals.tf` `threshold_rules`, `compute.tf` autoscaling resource |
| Spot/on-demand mixed pool | PARTIAL | `compute.tf` `preemptible_instance_config` |
| Break-glass key: Vault + KMS key required | SUBSTITUTE | `variables.tf` `generate_ssh_key`, `compute.tf` `oci_vault_secret` |
| WAF fail-open/fail-closed | no field exists | `loadbalancer.tf` WAF resource |
| Security groups -> NSGs | SUBSTITUTE (decided) | `network.tf` |

## Not yet implemented, deliberately

- **Identity.** No `oci_identity_dynamic_group` / `oci_identity_policy` is
  created. OCI has no per-instance role object; the fleet becomes a member of a
  dynamic group and policies grant that group verbs. The design is owned by
  `docs/multi-cloud-parity/oci/identity-model.md` and has not landed. Creating
  a guessed dynamic group here would be the thing thirteen other modules get
  written against.
- **Security rules.** Both NSGs are created empty on purpose; see `network.tf`.
- **Certificate issuance.** `ssl_certificate_ids` is supplied, never created.

## Oracle gate

Status: **not consulted.** Three decisions in this module are gate-required
(framework §4.1) and are implemented as the check sheet's proposed workaround,
not as an approved design:

1. `traffic_split_mode` - shared backend set vs listener cutover.
2. The threshold-rule boundaries translating `target_value = 70`.
3. The two-pool spot workaround.

## Validation reached

Rung 1 (`terraform validate`) and rung 2 (`terraform fmt`). Rungs 3-5 are the
orchestrator's; rung 6 is a human decision.
