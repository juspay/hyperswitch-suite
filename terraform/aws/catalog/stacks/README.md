# AWS catalog stacks

This directory contains Terragrunt Stack templates. A stack is a reusable,
environment-agnostic composition of catalog units. It is rendered into a live
environment tree by a `terragrunt.stack.hcl` file (for example,
[`terraform/aws/live/terragrunt.stack.hcl`](../live/terragrunt.stack.hcl) or
the one produced by [`scripts/self-host/generate.sh`](../../../scripts/self-host)).

Stacks are the source of truth for how catalog units are wired together. The
generated live tree is committed, but should be regenerated after any stack or
unit change.

## Available stacks

| Stack | Audience | VPC mode | Units | Environments |
|---|---|---|---|---|
| [`internal`](./internal/README.md) | Internal Juspay deployments | Stack creates the VPC | 26 units — full network, data, proxies, compute, K8s resources, apps and security rules | `dev`, `pre-prod`, `prod` |
| [`standalone`](./standalone/README.md) | Self-hosting merchants | Bring-your-own VPC | 6 units — database, ElastiCache, EFS, EKS, EKS resources and security rules | `prod`, `sandbox` |

## Choosing a stack

- Use **`internal`** if you want the full, opinionated Hyperswitch deployment
  and are okay with the stack owning the VPC, DNS, TLS, proxies, locker and
  observability stack. This is the stack rendered by
  `terraform/aws/live/terragrunt.stack.hcl` for the internal environments.

- Use **`standalone`** if you already have a VPC and want a minimal,
  self-hosted Hyperswitch footprint. It is consumed by
  `scripts/self-host/generate.sh`, which prompts for your VPC and subnet IDs
  and renders a merchant-specific live layer.

## Common conventions

- Every unit `path` is load-bearing. Unit `dependency { config_path = "../..." }`
  blocks are written against these exact layouts; renaming a path breaks the
  graph.
- Every stack provides its own `root.hcl` with the state backend, provider and
  shared locals for the units it renders.
- Generated state keys follow the pattern
  `<env>/<region>/<unit-path>/terraform.tfstate`. The ArgoCD `tfstate` Helm
  plugin reads from these paths, so they must stay in sync with the unit
  `path`s.

## Workflow

```bash
# Render an internal environment
cd terraform/aws/live
terragrunt stack generate
git status   # review the generated tree before committing

# Render a self-host environment (merchant fork)
./scripts/self-host/generate.sh --target-dir ./my-hyperswitch-config
```
