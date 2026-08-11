# load-balancer (OCI)

OCI equivalent of `terraform/aws/modules/composition/load-balancer` (ALB + optional Route53 zone/records). Raw
`oci` provider resources — no verified registry module exists for OCI Load Balancer.

## Mapping notes

| AWS | OCI |
|---|---|
| `aws_lb` | `oci_load_balancer_load_balancer` (`shape = "flexible"`, bandwidth range instead of a fixed size) |
| Target group (`aws_lb_target_group` + attachments) | Backend set (`oci_load_balancer_backend_set` + `oci_load_balancer_backend`) — OCI backend sets own the health checker directly, no separate target-group health-check resource |
| `aws_lb_listener` | `oci_load_balancer_listener` |
| `aws_route53_zone` / `aws_route53_record` (alias to the LB) | `oci_dns_zone` / `oci_dns_rrset` (plain `A` record to the LB's IP — OCI Load Balancers don't have a Route53-alias-style zone-apex integration, so this is a regular record, not an alias) |

For a fuller-featured standalone DNS/certificate setup, see the sibling `../route53` and `../acm` modules — this
module's `create_dns_zone`/`dns_records` inputs are a lightweight inline equivalent of the AWS module's bundled
Route53 support, same relationship the AWS `load-balancer` module has with its own inline Route53 resources vs.
the standalone `route53` composition module.
