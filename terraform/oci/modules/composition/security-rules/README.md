# Security Rules Module (OCI)

Cross-module network permissions for the OCI stack, applied **last**. Port of
`terraform/aws/modules/composition/security-rules`; the same architectural role
`terraform/gcp/modules/composition/firewall-rules` plays on GCP.

## Design pattern

Two phases, unchanged from AWS:

- **Phase A** - every composition module creates and *attaches* its own Network
  Security Group(s) and exports the OCIDs. Attachment lives with the resource
  that owns the VNIC: `create_vnic_details.nsg_ids` (compute),
  `node_config_details.nsg_ids` and `...pod_nsg_ids` (OKE),
  `endpoint_config.nsg_ids` (OKE control plane),
  `network_security_group_ids` (load balancer).
- **Phase B - this module** - runs last and creates every rule that crosses a
  module boundary, writing into NSGs owned by *other* Terraform states.

| Scenario | Location |
|---|---|
| Cross-module reference (jump host -> locker SSH) | here |
| Same-module internal (locker LB -> locker instance) | the owning module |

Running last turns the locker <-> jump-host cycle into a DAG, which is what
lets the other units apply in parallel. It is also the audit surface: one file
answers "what can talk to what", with a `description` on every rule.

## NSGs only, never security lists

Binding decision - see `docs/multi-cloud-parity/oci/network-security-model.md`
§5 in `hyperswitch-infra`. Summary:

- 83% of the live AWS rule set names a peer security group, and only NSG rules
  have `source_type`/`destination_type = "NETWORK_SECURITY_GROUP"`. Security
  list rules support only `CIDR_BLOCK` and `SERVICE_CIDR_BLOCK`.
- Only NSGs have a standalone per-rule resource
  (`oci_core_network_security_group_security_rule`). Security list rules are
  inline-only on `oci_core_security_list`, so a last-phase module could not
  attach a rule to a list it does not own - the module could not exist.
- `oci_core_network_security_group` has **no inline-rule argument at all**, so
  two states can never contend over an NSG's rule set. Structurally cleaner
  than AWS, where an `aws_security_group` with inline `ingress` blocks fights
  `aws_security_group_rule`.
- Oracle recommends NSGs over security lists, and specifically so for OKE.

**Prerequisite this module asserts:** the VCN default security list must be
empty. OCI unions security-list and NSG rules (`OR`), rules are allow-only, and
a subnet that does not set `security_list_ids` inherits the default list - whose
stock contents are allow-all egress and SSH-22 ingress. If it is not neutered by
`composition/vpc-network`, every egress rule this module writes is decorative.
`guards.tf` fails the plan on a non-empty default list.

**Single named exception to the NSG-only model:** the OCI Bastion service's
data-plane VNIC has no NSG support, so `composition/vpc-network` carries its
egress on a dedicated `management-bastion` security list attached to the
management subnet only. `guards.tf` hard-fails the plan if any OTHER non-default
security list exists, or if the management-bastion list gains any ingress rule.

## Input vocabulary

The live layer keeps the **AWS** vocabulary - `from_port`, `to_port`,
`protocol = "tcp"`, `cidr = [...]` - so the AWS rule set ports mechanically.
Every OCI translation happens in `locals.tf`:

| AWS | OCI | Where |
|---|---|---|
| `protocol = "tcp"` | `protocol = "6"` + `tcp_options.destination_port_range` | `locals.protocol_numbers` |
| `protocol = "-1"` | `protocol = "all"`, no options block | same |
| `protocol = "icmp"`, `from_port`/`to_port` | `icmp_options { type, code }` | `main.tf` |
| `from_port = 0, to_port = 65535` | options block omitted (OCI rejects port 0) | `all_ports` |
| `sg_id = [...]` | `source_type = "NETWORK_SECURITY_GROUP"` | selector |
| `cidr = [a, b, c]` | three resources, `source_type = "CIDR_BLOCK"` | fan-out |
| `ipv6_cidr` | folded into `cidr` - OCI has one field for both families | selector |
| `prefix_list_ids = [s3]` | `service_cidr_label = "objectstorage"`, resolved from `data.oci_core_services` | selector |

## Known divergences

| # | Verdict | What |
|---|---|---|
| 7 | PARTIAL | OCI's `source`/`destination` is a single string, so an N-CIDR rule fans out into N resources. Done inside the module so the live input stays a list. |
| 9 | PARTIAL | Service CIDR labels replace managed prefix lists. Covers the S3 use 1:1 and removes the hand-maintained per-region `s3_prefix_list_id`, but there is no customer-managed named-IP-set: shared address lists are repeated and expanded at plan time. Also no PrivateLink-equivalent granularity - the label is region-wide, not per-bucket. |
| 16 | PARTIAL | 5 NSGs per VNIC, **not increasable**. Design constraint: keep NSGs scoped to tiers and roles, never to individual applications. |
| - | PARTIAL | An OCI service gateway has no VNIC and so no NSG, so AWS's `vpc_endpoint_ingress` chokepoint has no target. Replaced by per-consumer egress rules to the service CIDR label - N places to audit instead of 1. |

## Churn

The `for_each` key is `<nsg>_<sha256(rule identity)>_<sha256(target)>`, where
"identity" is description + ports + protocol + selector kind. Appending,
removing or reordering entries in an address list touches only the entries that
changed. A rule *edit* still changes the key and is a destroy-then-create with a
window where the allow does not exist - AWS-equivalent, but worth a maintenance
window or an add-before-remove two-apply sequence on the request path.

## Outputs

`ingress_rule_ids`, `egress_rule_ids`, `service_cidr_blocks`, and
`rules_summary` - which extends the AWS output with `rules_by_nsg` (counts
against the non-increasable 120/NSG ceiling), `by_selector` (the
NETWORK_SECURITY_GROUP / CIDR_BLOCK / SERVICE_CIDR_BLOCK split that validation
rung 5 checks) and `invalid_rules` (OCI flips `is_valid` to false when a
referenced peer NSG is deleted - traffic stops but the plan stays clean, so
this is a better dangling-reference signal than AWS gives).
