# envoy-audit-instance (OCI)

A **single, standalone** `oci_core_instance` booting the freshly-built hardened
Ubuntu 24.04 Envoy image, **outside** the envoy-proxy instance pool (which this
module does NOT create - no pool, no autoscaling, no load balancer, no storage,
no break-glass, no identity). Its only job is the security-team audit workflow
(`docs/hardening/oci-envoy-squid-hardening-workplan.md` §6 step 3): launch one
review box per new image, run the W1 baseline through Run Command, then
terminate it.

It is modelled on the `bastion-host` module's standalone-instance idiom and the
`envoy-proxy` module's correctness contract.

## What the module owns

| File | Resources |
|---|---|
| `compute.tf` | `oci_core_instance` x1 |
| `network.tf` | `oci_core_network_security_group` x1 + `oci_core_network_security_group_security_rule` (one per VPN/office CIDR, tcp:22 ingress) |
| `templates/` | `userdata.sh` (creates the non-root review user, hardens sshd, configures ufw to tcp:22 from the VPN ranges) |

## Hardened-by-default posture

- `image_id` is **REQUIRED** with no default and no PLACEHOLDER fallback - a
  plan fails loud until the hardened Envoy image OCID exists. It is fed from
  the same `values.custom_images.envoy` the pool unit reads.
- `ssh_public_key` is **REQUIRED**, passed from `values.security_team.ssh_public_key`
  at apply time (supplied by InfoSec). No key is baked into the box.
- No public IP: `assign_public_ip = "false"` per-VNIC + the `management` tier's
  own subnet-level `prohibit_public_ip_on_vnic = true`. Reached over the VPN by
  private IP only - the envoy tier's stance.
- `preserve_boot_volume = false` (fixed) so the terminate-after-audit lifecycle
  actually removes the boot volume.
- The `secreview`-style user-data hardens sshd (key-only, no root login) and
  restricts ufw to tcp:22 from the VPN/office source CIDRs only.

## Validation reached

Rung 1 (`terraform validate`) and rung 2 (`terraform fmt`). No apply - IaC
authoring only.