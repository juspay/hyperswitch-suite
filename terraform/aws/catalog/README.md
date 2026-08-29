# Terragrunt Catalog

Reusable Terragrunt units and stacks for deploying Hyperswitch on AWS.

```
catalog/
├── units/     # one directory per unit — a parameterized terragrunt.hcl
│              # wrapping a composition/application-resources module by git tag
└── stacks/
    └── standalone/   # single-region self-host composition (see its README)
```

## Units

Each unit follows the same skeleton: `include "root"` (resolved via
`find_in_parent_folders("root.hcl")`, which travels with the *stack* that
consumes the unit) → `terraform { source = git::…//terraform/aws/modules/…?ref=<tag> }`
→ `dependency` blocks with `mock_outputs` → `inputs`.

Units are parameterized through Terragrunt Stacks `values`:

- **BYO-VPC**: `database`, `elasticache`, `efs`, `eks-01` and `security-rules`
  accept `vpc_id` + subnet-id lists via values; when set, their `vpc-network`
  dependency is disabled.
- **Optional components**: `security-rules` takes `enable_<component>` flags so
  minimal stacks can omit squid/jump-host/locker/etc.
- **Environment-specific integrations** (management-cluster access, ECR
  pull-through caches, Wazuh enrollment, SES roles, base domains) are all
  values-driven with safe defaults — nothing environment-specific is hardcoded
  in this catalog.

## Consuming

- **Self-hosting**: use `scripts/self-host/generate.sh` (repo root), which
  renders a live stack file targeting `stacks/standalone`.
- **By git ref**: a stack file elsewhere can pin units with
  `source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/<unit>?ref=<unit tag>"`.

## Versioning

Unit tags follow `unit/<name>-v<module-version>-v<unit-revision>` (e.g.
`unit/database-v0.1.6-v8`); the wrapped module tag (`database-v0.1.6`) is
pinned inside the unit. Bump the unit revision whenever the unit file changes;
bump the module version pin deliberately and test with the standalone stack.

## CI

- `.github/workflows/terragrunt-validate.yml` — `terragrunt hclfmt --check` on
  catalog changes.
- `.github/workflows/sensitive-scan.yml` — `scripts/ci/check-sensitive.sh`
  gate: no internal identifiers or credentials may land in this repo.
