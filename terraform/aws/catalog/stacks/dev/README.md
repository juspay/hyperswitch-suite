# Dev stack

Full single-region composition of the catalog for the internal environments.
Start with `dev`; the same unit layout is promoted to `pre-prod` and `prod`
with larger sizing and real domains. This stack creates its own VPC and wires
up every catalog unit.

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

## Optional sizing values

All of these fall back to sensible defaults if omitted from
`terraform/aws/live/terragrunt.stack.hcl`:

| Value | Default | Consumed by |
|---|---|---|
| `system_nodes_desired_size` | `1` | `eks-01` |
| `system_nodes_min_size` | `1` | `eks-01` |
| `system_nodes_max_size` | `50` | `eks-01` |
| `generic_compute_desired_size` | `2` | `eks-01` |
| `generic_compute_min_size` | `1` | `eks-01` |
| `generic_compute_max_size` | `50` | `eks-01` |
| `monitoring` | *(omitted — node group not created)* | `eks-01` — full object `{ desired_size, min_size, max_size, instance_types, ami_id, max_unavailable_percentage }` |
| `keymanager` | *(omitted — node group not created)* | `eks-01` — full object as above |
| `auxillary` | *(omitted — node group not created)* | `eks-01` — full object as above |
| `root_volume_size` / `root_volume_type` | `20` / `"gp3"` | `eks-01` |
| `db_instance_class` | `"db.r5.large"` | `database` |
| `db_engine_version` | `"17.9"` | `database`, `locker`, `superposition` |
| `db_backup_retention_period` | `7` | `database` |
| `cache_node_type` | `"cache.m6g.large"` | `elasticache` |
| `cache_num_node_groups` | `2` | `elasticache` |
| `cache_replicas_per_node_group` | `1` | `elasticache` |
| `cache_node_group_configuration` | 2 shards | `elasticache` |
| `locker_instance_type` | `"t3.medium"` | `locker` |
| `locker_backup_retention_period` | `7` | `locker` |
| `locker_db_instance_class` | `"db.r6g.large"` | `locker` |
| `envoy_instance_type` | `"t3.medium"` | `envoy-proxy` |
| `envoy_root_volume_size` | `20` | `envoy-proxy` |
| `envoy_min_size` / `envoy_max_size` / `envoy_desired_capacity` | `1` / `10` / `1` | `envoy-proxy` |
| `jump_host_instance_type` | `"t3.medium"` | `jump-host` |
| `jump_host_root_volume_size` | `30` | `jump-host` |
| `squid_instance_type` | `"t3.medium"` | `squid-proxy` |
| `squid_min_size` / `squid_max_size` / `squid_desired_capacity` | `1` / `6` / `1` | `squid-proxy` |
| `squid_root_volume_size` | `30` | `squid-proxy` |
| `grafana_db_instance_class` | `"db.t4g.medium"` | `grafana` |
| `ratelimiter_cache_node_type` | `"cache.t3.small"` | `ratelimiter` |
| `superposition_backup_retention_period` | `7` | `superposition` |
| `superposition_db_instance_class` | `"db.r6g.large"` | `superposition` |

`terraform/aws/live/terragrunt.stack.hcl` currently fills the required values
with `REPLACE_ME`-style placeholders per environment — `terragrunt stack generate`
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
