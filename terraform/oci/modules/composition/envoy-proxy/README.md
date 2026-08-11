# envoy-proxy (OCI)

OCI equivalent of `terraform/aws/modules/composition/envoy-proxy` (self-managed Envoy instances behind an ASG +
ALB, with separate HTTP/HTTPS/mTLS listeners). Same instance-pool pattern as `../squid-proxy`, but fronted by an
L7 `oci_load_balancer_load_balancer` (matching the AWS module's use of an ALB rather than an NLB).

## mTLS listener mapping

AWS models mutual TLS as a `mutual_authentication { mode, trust_store_arn }` block on an `aws_lb_listener`. OCI
Load Balancer listeners express the same thing via `ssl_configuration.verify_peer_certificate = true` +
`trusted_certificate_authority_ids` (from `oci_certificates_management_certificate_authority` resources, not the
`../acm` module's leaf certificates) — there's no separate "trust store" resource type.

## Not modeled here (see `../squid-proxy/README.md` for the same caveats)

- ASG scaling policies / instance refresh / spot mix — add `oci_autoscaling_auto_scaling_configuration` if needed.
- Listener rules (header/path-based routing, `aws_lb_listener_rule`) — OCI's equivalent is
  `oci_load_balancer_rule_set` + `oci_load_balancer_path_route_set`, not wired up in this minimal module; add if
  the Envoy routing configuration needs LB-level (not just Envoy-config-level) routing rules.
- WAF association (`aws_wafv2_web_acl_association`) — see `../cloudfront/README.md`; attach
  `oci_waf_web_app_firewall` to `oci_load_balancer_load_balancer.envoy[0].id` the same way.
