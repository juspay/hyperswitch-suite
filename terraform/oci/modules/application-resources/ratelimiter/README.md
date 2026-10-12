# ratelimiter (OCI)

**This module creates no resources.** There is no `main.tf`. It is a statement
factory plus a pass-through for the dedicated cache's connection details.

Both halves of that are deliberate and both are explained in full at the top of
`variables.tf`:

- **The identity grants nothing.** `identity-model.md` section 1.2 records this
  workload as "1 SA x 0 grants - STS only". All three AWS policy inputs are
  empty in all six live roots. On AWS an empty role is still an object with an
  ARN; on OCI an identity **is** its statements, so zero grants is zero
  statements and there is nothing to create. `policy_statements` is `[]`.
- **The dedicated cache is a sibling unit, not a nested module.** AWS embeds
  `composition/elasticache` inside this module. Here it is a second
  `oci-cache-valkey` unit (`name_suffix = "ratelimiter"`) so the security-last
  rules unit can reach its `nsg_id`, so sizing is a stack `value`, and so a
  tens-of-minutes cache create does not block this module's plan.

What is **not** ported: the load-balancer security group, which enforces zero
rules in every AWS live root. See check sheet open question 3.

Check sheet: `docs/multi-cloud-parity/oci/modules/ratelimiter.md`.
