# ratelimiter (OCI)

**This module creates no resources.** There is no `main.tf`. It is a statement
factory plus a pass-through for the dedicated cache's connection details.

Both halves are deliberate:

- **The identity grants nothing.** This workload is "1 service account x 0
  grants". All three AWS policy inputs are empty in every live root. On AWS an
  empty role is still an object with an ARN; on OCI an identity **is** its
  statements, so zero grants is zero statements and there is nothing to create.
  `policy_statements` is `[]`.
- **The dedicated cache is a sibling unit, not a nested module.** AWS embeds
  `composition/elasticache` inside this module. Here it is a second
  `oci-cache-valkey` unit (`name_suffix = "ratelimiter"`) so the security-last
  rules unit can reach its `nsg_id`, sizing can be a stack `value`, and a
  tens-of-minutes cache create does not block this module's plan.

Not ported: the load-balancer security group, which enforces zero rules in every
AWS live root.