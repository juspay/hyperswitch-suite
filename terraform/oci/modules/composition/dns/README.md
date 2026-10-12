# dns

OCI DNS zones and records.

## The one thing to know

**A private zone is invisible inside the VCN until the VCN's resolver is told
about it, and skipping that step produces no error.** OCI needs three objects
for zone + VCN visibility, one of which (`oci_dns_resolver`) this module does
not own — OCI auto-creates it with the VCN, and the Terraform resource can only
update it. That lives in `resolver.tf`. The `private_zones_resolvable_in_vcn`
output exists so the silent case can be asserted against.

`attached_views` is authoritative: anything attached out of band gets detached.
Use `additional_attached_view_ids` if a second owner exists.

## Known limitations

None of the advanced routing policies (weighted, failover, geo, latency, CIDR)
is built; all records are plain records. On OCI each policy needs a separate
steering policy plus attachment, and none is currently used.

## Pointing a domain at a load balancer

Use a plain `A` record at the load-balancer module's `ip_address` output. OCI
load balancers get real IPs, so the apex/ALIAS problem does not arise. What is
lost is health-gated routing; the equivalent is a steering policy with a HEALTH
rule plus a Health Checks monitor, not built here.