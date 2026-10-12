# dns

OCI port of `terraform/aws/modules/composition/route53`. GCP sibling:
`terraform/gcp/modules/composition/cloud-dns`.

Check sheet: `docs/multi-cloud-parity/oci/modules/route53.md` (hyperswitch-infra).
Strategy: DIRECT-RESOURCE.

## The one thing to know

**A private zone is invisible inside the VCN until the VCN's resolver is told
about it, and skipping that step produces no error.** AWS does zone + VPC
visibility in one resource. OCI needs three objects, one of which
(`oci_dns_resolver`) this module does not own - OCI auto-creates it with the
VCN, and the Terraform resource can only update it. All of that lives in
`resolver.tf`, deliberately in its own file. The `private_zones_resolvable_in_vcn`
output exists so the silent case can be asserted against.

Two corrections to the check sheet, found while building:

1. **No new vpc-network output is needed.** The data source
   `oci_core_vcn_dns_resolver_association` maps `vcn_id` -> resolver OCID, so
   the unit passes the `vcn_id` it already reads. The coupling the check sheet
   anticipated is real but narrower than expected.
2. **The resolver attachment plans as a `create`, not an `update`.** That is a
   new Terraform state entry; the provider's Create issues an `UpdateResolver`
   API call. Nothing is provisioned. `route53.md` rung 5 says to treat a
   `create` here as a bug - it is not.

`attached_views` is authoritative: anything attached out of band gets detached.
Use `additional_attached_view_ids` if a second owner exists.

## Parity summary

3 FULL / 6 PARTIAL / 2 SUBSTITUTE / 3 NONE.

| Feature | Verdict | Where it is commented |
|---|---|---|
| 2 private zone + VCN visibility | PARTIAL | `resolver.tf` header |
| 4 alias record at the apex | PARTIAL | `main.tf`, above `oci_dns_rrset` |
| 5/6/7/10 weighted, failover, geo, CIDR routing | PARTIAL | `variables.tf`, `zones` |
| 8/9 geoproximity bias, latency routing | NONE | `variables.tf`, `zones` |
| 11/12 multivalue, health-check-linked record | SUBSTITUTE | `variables.tf`, `zones` |
| 13 reusable delegation set | NONE | `variables.tf`, `zones` |

None of the routing policies is built. Every one of them is unused by every
live AWS instantiation - all records are plain CNAMEs - and on OCI each needs a
separate steering policy plus attachment. Building them now would be porting
plumbing. `route53.md` section 4 holds the mapping for when a consumer appears.

## Pointing a domain at a load balancer

Use a plain `A` record at `composition/load-balancer`'s `ip_address` output.
OCI load balancers get real IPs, so the apex problem Route 53's ALIAS record
exists to solve does not arise. What is lost is `evaluate_target_health`; the
equivalent is a steering policy with a HEALTH rule plus a Health Checks
monitor, not built here.
