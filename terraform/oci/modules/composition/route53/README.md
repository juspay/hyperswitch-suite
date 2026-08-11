# route53 (OCI) → OCI DNS

OCI equivalent of `terraform/aws/modules/composition/route53`. Uses `oci_dns_zone` / `oci_dns_rrset`. No verified
registry module exists for OCI DNS - raw `oci` provider resources.

## Key structural difference

AWS models one record = one `aws_route53_record` resource, with all the routing-policy variants (weighted,
latency, geoproximity, failover, ...) as attributes on that single resource. OCI's DNS API groups records by
`(domain, rtype)` into a single **RRSet** (`oci_dns_rrset`) containing an `items` list — you can't have two
separate weighted `oci_dns_rrset` resources for the same domain/type the way AWS allows two `set_identifier`
variants of the same record. OCI DNS also has no equivalent of AWS's weighted/latency/geoproximity/failover
routing policies; for that kind of traffic steering, use OCI Traffic Management Steering Policies
(`oci_dns_steering_policy`) layered in front of the zone instead.
