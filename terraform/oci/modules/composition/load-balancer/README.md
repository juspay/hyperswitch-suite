# load-balancer

OCI port of `terraform/aws/modules/composition/load-balancer`. GCP sibling:
`terraform/gcp/modules/composition/load-balancer`.

Check sheet: `docs/multi-cloud-parity/oci/modules/load-balancer.md`.
Cross-cutting: `docs/multi-cloud-parity/oci/edge-tier-strategy.md`.
Strategy: DIRECT-RESOURCE.

## Scope

**L7 only** - `oci_load_balancer_load_balancer`, the OCI Load Balancer service.
The AWS original hardcodes `load_balancer_type = "application"` and has no NLB
toggle; AWS's own NLB primitives (`base/nlb`, `base/nlb-listener`) are wired
into zero composition modules and zero live roots.

The OCI **Network Load Balancer** (L4) is therefore **not built**, deliberately.
Its mapping is verified and recorded (`load-balancer.md` feature 15) and ready
to reuse when a real TCP-passthrough consumer appears. Worth knowing if it ever
is: its listener schema has no `ssl_configuration` field at all - pure L3/L4
passthrough, stricter than AWS's NLB.

**Oracle gate item 1 (build the NLB now or defer) is NOT YET CONSULTED.** The
default taken is the check sheet's own recommendation, and nothing depends on
it yet, so the gate can still reverse it cheaply.

## What this module does not own

| Concern | Owner | Contract this module provides |
|---|---|---|
| DNS zone + records | `composition/dns` | `ip_address` for a plain A record |
| WAF attachment | whoever owns the WAF policy | `load_balancer_id` |
| NSG rules | `catalog/units/oci/security-rules` | `nsg_id` on an empty NSG |
| Certificate issuance | `composition/certificates-management` | consumes `certificate_ids` |

The AWS module bundles optional Route 53 zone creation and its own alias
record. Not ported - two modules fighting over one zone is the failure that
avoids.

## Parity summary

10 FULL / 4 PARTIAL / 1 SUBSTITUTE / 0 NONE.

| Feature | Verdict | Where commented |
|---|---|---|
| 3 listener default actions beyond forward | PARTIAL | `listeners.tf`, rule sets |
| 5 additional SNI certificates per listener | PARTIAL | `listeners.tf`, `ssl_configuration` |
| 7 HTTP/2 | PARTIAL, unverified | `main.tf` header |
| 8 WAF fail-open | SUBSTITUTE | `main.tf` header |
| 10 access logging | PARTIAL, unverified | `main.tf` header |
| 15 L4 passthrough role | mapping only, not built | `main.tf` header |

One check-sheet open question closed while building: **`oci_load_balancer_rule_set`
does carry a REDIRECT action** with `redirect_uri` and `response_code`, so
bare-HTTP-to-HTTPS has a real equivalent (via `rule_sets` + `rule_set_names`).
`fixed-response` still has none - use a trivial always-healthy backend set.

Two questions remain open: whether `oci_load_balancer_hostname` lifts the
one-certificate-per-listener limit, and whether HTTP/2 and access logging exist
anywhere. No variable in this module pretends any of them is settled.

## Structural change worth knowing

**This module owns backend sets.** OCI's listener requires
`default_backend_set_name`, and a backend set is a sub-resource of the load
balancer - it cannot exist before or outside it. The listener-to-backend chain
AWS splits across two modules lives in one here. Leave `backends` empty for
anything OKE registers through its own cloud-controller-manager; two registrars
on one backend set makes it flap.
