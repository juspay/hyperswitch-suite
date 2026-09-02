# Self-host generator (maintainers)

`generate.sh` renders the self-host bundle (terragrunt live stack + ArgoCD
app-of-apps + values + runbook). Three ways to invoke it:

- **in-repo** (default): renders into this checkout — for merchants working in
  a fork of hyperswitch-suite;
- **destination** (`--target-dir <path>`): renders into a separate directory,
  vendoring `terraform/aws/catalog/{units,stacks/standalone}` and
  git-initializing it, producing a self-contained config repo;
- **no checkout** (`bootstrap.sh`): a curl-pipeable wrapper that downloads a
  throwaway tarball snapshot of the repo (no git, no persistent checkout),
  runs `generate.sh --target-dir <path>` from inside it, then deletes the
  snapshot. Requires `--target-dir` (there is nothing to default to).

Merchants run it; this README is for maintaining it.

## Layout

```
generate.sh          # prompt flow + render orchestration
bootstrap.sh          # curl-pipeable wrapper: fetch a tarball snapshot, hand off to generate.sh
lib/common.sh        # prompt_var, validators, to_hcl_list/to_bool
lib/config.sh        # CONFIG_KEYS + hyperswitch-bootstrap.conf load/save
lib/render.sh        # TOKEN_KEYS + pure-bash __TOKEN__ renderer + leak assertion
templates/           # everything that gets rendered (see below)
templates/fixtures/ci.conf   # complete non-interactive answer set for CI
```

`bootstrap.sh` is deliberately self-contained (its own `info`/`ok`/`die`
helpers, no `source` of `lib/*.sh`) — it runs before anything has been
downloaded, so it can't depend on files that only exist after the fetch.

## Token registry

Templates use `__TOKEN__` placeholders (never `{{...}}` or `${...}`, which
belong to ArgoCD/Terragrunt). Every token must be listed in
`lib/render.sh:TOKEN_KEYS`; every prompted key in `lib/config.sh:CONFIG_KEYS`.
`render_file` fails the run if a rendered file still contains `__[A-Z_]+__`.

Derived tokens (computed in generate.sh, not prompted): `ENV_SHORT`,
`*_HCL` list forms, `EKS_AMI_ID_HCL`, `KARPENTER_ENABLED`, `ESO_ENABLED`,
`CONTROL_CENTER_ENABLED`, `OPTIONAL_APP_VALUEFILES`.

## Invariants

- Terragrunt unit `path`s in `catalog/stacks/standalone` must match the
  `$tfstate.*` S3 paths in `templates/argocd/apps/**` — they encode
  `<env>/<region>/<unit-path>/terraform.tfstate`.
- `templates/infra-configurations/hyperswitch-stack/values.yaml.tpl` key paths
  must match the pinned hyperswitch-stack chart tag (`HS_CHART_VERSION`
  default). Re-verify with `helm template` when bumping the default.
- Nothing under `templates/` may contain internal Juspay data —
  `scripts/ci/check-sensitive.sh` gates every PR.

## Bumping versions

- Chart versions: monitoring quartet + argo chart pins live in
  `templates/argocd/**`; the hyperswitch-stack default in `generate.sh`.
- Unit changes: edit `terraform/aws/catalog/units/**`, then cut a new
  `unit/<name>-v<module>-v<rev>` tag (see `terraform/aws/catalog/README.md`).

## CI

`.github/workflows/self-host-bundle.yml` renders the fixture bundle, scans it,
runs `terragrunt stack generate`, and helm-templates the argocd-apps chart and
the vendored istio chart.
