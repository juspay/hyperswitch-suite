# Internal stack

Full single-region composition of the catalog for the internal `dev`,
`pre-prod` and `prod` environments. Unlike [`stacks/standalone`](../standalone/README.md)
(BYO-VPC, used by the self-host generator), this stack creates its own VPC and
wires up every catalog unit.

Rendered by `terraform/aws/live/terragrunt.stack.hcl` — one `stack` block per
environment — into `terraform/aws/live/<env>/<region>/`.

## Units and phases

| Phase | Units | `path` |
|---|---|---|
| 1. Network & DNS | `vpc-network`, `route53`, `acm` | `vpc-network`, `route53`, `acm` |
| 2. Data layer | `database`, `elasticache`, `efs`, `kafka`, `locker` | same |
| 3. Proxies & access | `squid-proxy`, `envoy-proxy`, `jump-host` | same |
| 4. Compute | `eks-01` | `application-stack/eks-01` |
| 5. K8s resources | `eks-resources`, `utils-load-balancer` | `application-stack/eks-resources`, `application-stack/utils-load-balancer` |
| 6. Apps | `alb-controller`, `external-secrets`, `istio`, `otel`, `vector-dr`, `loki`, `grafana`, `ratelimiter`, `hyperswitch`, `decision-engine`, `superposition` | `application-stack/apps/<name>` |
| 7. Security rules | `security-rules` (apply last) | `security-rules` |

26 units total. `hyperswitch` must land before `decision-engine` and
`superposition` — both depend on its KMS key output.

**The `path` values above are load-bearing.** Every unit's
`dependency { config_path = "../..." }` (e.g. `apps/istio`'s
`config_path = "../../eks-01"`, `eks-resources`' `config_path = "../../efs"`)
is written against this exact layout. Do not rename a unit's `path` here
without updating every other unit's `config_path` that points at it.

## VPC mode

No unit in this stack is passed `vpc_id` / `*_subnet_ids`. Every VPC-consuming
unit's `dependency "vpc" { enabled = try(values.vpc_id, null) == null }` toggle
therefore resolves to `true`, and the unit reads its networking inputs from the
`vpc-network` unit created here instead. See `units/database/terragrunt.hcl`
for the canonical form of this pattern.

## Required values

These come from `terraform/aws/live/terragrunt.stack.hcl` and hard-fail the
relevant unit if missing (as opposed to `try(values.X, default)` fields, which
are optional):

| Value | Consumed by |
|---|---|
| `vpc_cidr_prefix` | `vpc-network` |
| `base_domain` | `route53`, `acm`, `envoy-proxy` (SES fallback), `grafana`, `superposition` |
| `ami_id` | `locker`, `squid-proxy`, `envoy-proxy`, `jump-host` |
| `virtual_hosts_domains` | `envoy-proxy` — a map of lists, e.g. `{ api = ["api.dev.example.com"] }` |
| `istio_host_domains` | `istio` — passed through as the unit's `host_domains` |
| `admin_role_arn` | `eks-01` (becomes `admin_sso_role_arn`) |
| `admin_access_cidrs` | `eks-01` (public endpoint access list; pass `[]` if unused) |
| `eks_instance_types` | `eks-01` (`system_nodes` and `generic_compute` node groups) |

`terraform/aws/live/terragrunt.stack.hcl` currently fills these with
`REPLACE_ME`-style placeholders per environment — `terragrunt stack generate`
succeeds, but `terragrunt run-all plan` will not until real values are filled
in.

## Prerequisites

- An existing, versioned + encrypted S3 bucket per environment for
  `values.state_bucket` (`remote_state.disable_bucket_update = true` — this
  stack does not create or modify the bucket).
- Terragrunt >= 1.1.

## Workflow

```bash
cd terraform/aws/live
terragrunt stack generate       # renders the unit tree into <env>/<region>/
git add . && git commit          # the generated tree is committed

cd dev/eu-central-1
terragrunt run-all apply         # applies units in dependency order
```
