# Security Rules Module (OCI)

Cross-module network permissions for the OCI stack, applied **last**.

## Design pattern

- **Phase A** — every composition module creates and attaches its own Network
  Security Group(s) and exports the OCIDs. Attachment lives with the resource
  that owns the VNIC.
- **Phase B — this module** — runs last and creates every rule that crosses a
  module boundary, writing into NSGs owned by *other* Terraform states.

Running last turns cross-module dependencies into a DAG, which is what lets
the other units apply in parallel. It is also the audit surface: one file
answers "what can talk to what", with a `description` on every rule.

## NSGs only, never security lists

- Only NSG rules support `source_type`/`destination_type =
  "NETWORK_SECURITY_GROUP"`; security list rules support only `CIDR_BLOCK` and
  `SERVICE_CIDR_BLOCK`.
- Only NSGs have a standalone per-rule resource; security list rules are
  inline-only and cannot be attached by a module that does not own the list.
- `oci_core_network_security_group` has no inline-rule argument, so two states
  cannot contend over an NSG's rule set.

**Prerequisite:** the VCN default security list must be empty. OCI unions
security-list and NSG rules (`OR`); a subnet that inherits the default list gets
allow-all egress and SSH-22 ingress, which would make every egress rule here
decorative. `guards.tf` fails the plan on a non-empty default list.

## Input vocabulary

The live layer keeps the source-cloud vocabulary (`from_port`, `to_port`,
`protocol = "tcp"`, `cidr = [...]`); every OCI translation happens in
`locals.tf`. OCI uses protocol numbers (`"6"` for tcp), `icmp_options { type,
code }`, and omits the options block for all-ports (OCI rejects port 0). A
single `cidr` list fans out into one rule per address. Service CIDR labels
(`service_cidr_label`) replace managed prefix lists.

## Known divergences

- OCI's `source`/`destination` is a single string, so an N-CIDR rule fans out
  into N resources (done inside the module).
- 5 NSGs per VNIC, not increasable — scope NSGs to tiers and roles, never to
  individual applications.
- An OCI service gateway has no VNIC and no NSG, so the source-cloud endpoint
  ingress chokepoint has no target; use per-consumer egress rules to the service
  CIDR label.

## Churn

The `for_each` key is `<nsg>_<sha256(rule identity)>_<sha256(target)>`.
Appending or removing entries touches only the entries that changed; a rule
*edit* is a destroy-then-create with a window where the allow does not exist.

## Outputs

`ingress_rule_ids`, `egress_rule_ids`, `service_cidr_blocks`, and
`rules_summary` (`rules_by_nsg` against the 120/NSG ceiling, `by_selector`, and
`invalid_rules` — OCI flips `is_valid` to false when a referenced peer NSG is
deleted, a better dangling-reference signal than a silent allow-retain).