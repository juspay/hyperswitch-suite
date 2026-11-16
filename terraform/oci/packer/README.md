# OCI custom image builders (Packer)

Packer templates that build the custom OCI images the VM-tier composition
modules need. These are **not** Terraform modules — they are never consumed via
a `module` block or a `terragrunt source = "git::…"` ref, so they live here as a
sibling to `../modules/`, not nested inside it. Each template builds an image
and hands off a plain image **OCID**; the consuming composition module takes
that as an input variable and knows nothing about how it was built.

Same structure and the same reason as [`../../gcp/packer/`](../../gcp/packer),
whose templates these are ported from.

## Image → composition module mapping

| Image dir | Consuming composition module | Terraform input it feeds | Wired into |
|---|---|---|---|
| [`envoy-proxy/`](./envoy-proxy) | `../modules/composition/envoy-proxy` | `image_id` | `hyperswitch-infra:terraform/oci/live/terragrunt.stack.hcl` → `values.custom_images.envoy` |
| [`squid-proxy/`](./squid-proxy) | `../modules/composition/squid-proxy` | `image_id` | …→ `values.custom_images.squid` |
| [`shared/`](./shared) | — | — | provisioner scripts both templates use |
| [`build-network/`](./build-network) | — | — | disposable VCN the builds run in |

Directory names match the composition module name exactly (`envoy-proxy`, not
`envoy`) so the mapping stays 1:1 and greppable.

## Build

```bash
# once per build session - creates a disposable VCN/subnet/IGW
cd terraform/oci/packer/build-network
COMPARTMENT_ID=ocid1.compartment.oc1..xxxx ./create.sh

cd ../squid-proxy
cp dev.auto.pkrvars.hcl.example dev.auto.pkrvars.hcl   # fill in the three OCIDs
packer init .
packer validate .
packer build .

# when finished
cd ../build-network && ./destroy.sh
```

`packer validate` is worth running on its own, not just as a formality: it runs
the builder's `Prepare()`, which constructs and validates the whole OCI auth
chain. A stale `oci session` shows up there in seconds rather than ten minutes
into a build.

## What this port had to solve that the GCP one did not

Recorded here because all four are things the next VM-tier image
(`kafka`, `cassandra`, `clickhouse`) will hit identically, and
`docs/multi-cloud-parity/oci/vm-tier-and-images.md` §4 explicitly asks for the
shared parts to be factored once rather than rediscovered per module.

1. **Reaching the build instance.** GCP tunnels over IAP (imperfectly — see
   `hashicorp/packer#12169`). `packer-plugin-oracle` has **no bastion
   argument at all** — verified by reading `builder/oci/config.go`, whose entire
   network/auth surface is `access_cfg_file`, `access_cfg_file_account`,
   `subnet_ocid`, `create_vnic_details` and `use_private_ip`. Packer's *generic*
   `ssh_bastion_*` communicator settings could in principle be pointed at an OCI
   Bastion port-forwarding session, but no Bastion service instance exists in
   this tenancy (`bastion-host` is unported), so that path is untested and would
   require creating persistent infrastructure by hand. Resolution: a disposable
   build VCN with a build-time public IP, argued in full in
   `build-network/create.sh`.

2. **Authentication with a session-token profile.** The `devuser` profile has no
   `user` key and signs with `security_token_file`. The builder *declares* a
   `security_token_file` argument but never reads it — it is vestigial. What
   actually works is the OCI Go SDK's file configuration provider, which returns
   an `ST$…`-prefixed key ID when the profile carries that key. Nothing extra
   needs to be passed; `access_cfg_file_account = "devuser"` is enough.

3. **The apt-lock barrier.** GCP guards its first `apt-get` with
   `cloud-init status --wait`. Necessary here and **proven insufficient** — see
   `shared/scripts/wait-for-apt.sh`.

4. **Config delivery has to live in the image.** GCP deliberately moved config
   fetching *out* of its images and into a live-layer startup script. The OCI
   composition modules have no startup-script seam and instead pass
   `config_bucket`/`config_namespace` through instance metadata, i.e. the image
   is expected to fetch. That needs the OCI CLI baked in
   (`shared/scripts/install-oci-cli.sh`) and, eventually, an instance principal
   that does not exist yet.

## The identity gap, stated plainly

Neither image can currently read its config bucket. `oci os object get` requires
an instance principal, which requires an `oci_identity_dynamic_group` plus an
`oci_identity_policy`; both composition modules deliberately create neither
(their READMEs: *"Not yet implemented, deliberately: Identity"* — the design is
owned by `docs/multi-cloud-parity/oci/identity-model.md` and has not landed).

Both images therefore ship a **fail-closed default** and both fetch scripts fail
**soft**:

- squid boots its baked-in `squid.conf` with an **empty** allowlist → denies all
  egress rather than permitting anything unintended;
- envoy boots a config that answers **503 to everything, including the load
  balancer's health check** → the instance registers and then reports unhealthy,
  rather than passing a health check while black-holing traffic.

This is the honest state of the pipeline, not a placeholder pretending to work.
When the identity model lands, nothing in these images changes — the fetch
scripts start succeeding.
