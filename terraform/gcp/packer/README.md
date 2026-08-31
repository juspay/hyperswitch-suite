# GCP custom image builders (Packer)

Packer templates that build the custom GCE images GCP's VM/MIG-tier
composition modules need. These are **not** Terraform modules — they're
never consumed via a `module` block or a `terragrunt source = "git::..."`
ref, so they live here as a sibling to `../modules/`, not nested inside it.
Each template builds an image and hands off a plain image name/self-link;
the consuming composition module takes that as an input variable and knows
nothing about how it was built.

GCP's managed-instance-group model has no userdata-only path the way AWS's
ASG + `custom_userdata` does (see the AWS composition modules of the same
name, which only ever template config into an *already-installed* binary at
boot) — on GCP the binary has to be baked into the image itself, hence a
Packer build step per VM-tier component.

## Image → composition module mapping

| Image dir | Consuming composition module | Terraform input it feeds |
|---|---|---|
| [`envoy-proxy/`](./envoy-proxy) | `../modules/composition/envoy-proxy` | `envoy_image` |
| [`squid-proxy/`](./squid-proxy) | `../modules/composition/squid-proxy` | `squid_image` |
| [`locker/`](./locker) | `../modules/composition/locker` | `locker_image` |

Directory names match the composition module name exactly (not shortened,
e.g. `envoy-proxy` not `envoy`) so the mapping stays 1:1 and greppable.

Add a row here whenever a new VM-tier component gets a Packer-built image —
`terraform/gcp/live/README.md` (in `hyperswitch-infra`) already lists
several more of these still pending (kafka, cassandra, clickhouse,
opensearch, locker).

## Build

Each subdirectory is a self-contained Packer template — see its own
README for the exact `packer build` invocation and what it installs.
