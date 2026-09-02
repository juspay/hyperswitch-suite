# Live layer

This directory holds the internal `dev`, `pre-prod` and `prod` environments,
generated from [`terraform/aws/catalog/stacks/internal`](../catalog/stacks/internal/README.md)
by [`terragrunt.stack.hcl`](./terragrunt.stack.hcl).

There is no hand-maintained Terraform here. `terragrunt.stack.hcl` is the only
file to edit; everything else under `dev/`, `pre-prod/` and `prod/` is
generated and then committed.

## Regenerating

```bash
cd terraform/aws/live
terragrunt stack generate
git status   # review the diff before committing
```

Run this after changing `terragrunt.stack.hcl` or any unit under
`catalog/units/`. `terragrunt stack generate` only renders files — it does
not evaluate unit inputs — so a clean generate does not mean `plan`/`apply`
will succeed.

## Applying

```bash
cd terraform/aws/live/dev/eu-central-1
terragrunt run-all apply
```

Units apply in dependency order (see the phase table in the
[internal stack README](../catalog/stacks/internal/README.md)); `security-rules`
always goes last.

## Placeholders

`terragrunt.stack.hcl` ships with `REPLACE_ME` placeholders for values that
can't be committed (AWS account IDs, AMI ids, IAM role ARNs, real domains —
`scripts/ci/check-sensitive.sh` gates the repo against exactly this class of
value). Fill these in for your account before running `plan`/`apply`:

- `account_id`, `admin_role_arn` — real IAM/account identifiers
- `ami_id` — a real AMI for the locker / squid-proxy / envoy-proxy / jump-host
  instances (they currently share one placeholder; use per-role AMIs if they differ)
- `base_domain`, `virtual_hosts_domains`, `istio_host_domains` — real domains
- `state_bucket` — must already exist (versioned, encrypted); this stack does
  not create it

Squid's egress allowlist lives outside this tree, at
`../../../whitelisted-domains/<env>-allowedlist.txt` — extend it with the
domains your deployment needs to reach.

## Known limitation

The self-host generator (`scripts/self-host/generate.sh`) also writes a
`terragrunt.stack.hcl` under `terraform/aws/live/<env>/` in a merchant's fork
of this repo, defaulting `env` to `prod`. Running the generator in a fork
without first removing this file's `prod` block will collide with it.
