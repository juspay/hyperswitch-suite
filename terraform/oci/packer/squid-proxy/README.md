# Squid custom image (OCI, Packer)

Builds the image the `squid-proxy` composition module's `image_id` input
expects (`../../modules/composition/squid-proxy/variables.tf`), and that
`hyperswitch-infra:terraform/catalog/units/oci/squid-proxy` passes through from
`values.custom_images.squid`.

That unit has **no fallback default** for `image_id` — it fails at plan time
rather than accepting a placeholder. That is deliberate and this directory is
the other half of the deal: the GCP port's one genuine failure here was a
catalog layer carrying `PLACEHOLDER-squid` while a hand-authored dev root
quietly pointed at a real image, so dev and the promotion path diverged
(`docs/multi-cloud-parity/oci/vm-tier-and-images.md` §2).

Ported from [`../../../gcp/packer/squid-proxy/`](../../../gcp/packer/squid-proxy).

## What this builds, on top of a stock `Canonical-Ubuntu-26.04` platform image

- **`squid`** from the Ubuntu apt repo. Same package the AWS AMI is built on;
  the AWS live layer's `userdata.sh` only ever templates config into an
  already-installed Squid.
- **A baked-in, fail-closed `/etc/squid/squid.conf`** (`scripts/squid.conf.default`)
  plus an **empty** `/etc/squid/squid.allowed.sites.txt`. The GCP image ships no
  default and leans on Ubuntu's stock config; this one does not, because a
  fetch-failed instance running Ubuntu's ACL set is running a *different* policy
  rather than a stricter subset of the intended one. With an empty allowlist the
  effective policy is deny-all.
- **`squid-config-fetch.service`** — oneshot, `Before=squid.service`, pulls
  `squid.conf` from Object Storage and **validates it with `squid -k parse`
  before installing it**. Neither the AWS nor the GCP version validates; both
  will happily install a config that takes the fleet down on next boot.
- **`squid-whitelist-fetch.service` + `/etc/cron.d/squid-whitelist-update`** —
  the allowlist hot-reload, every 15 minutes, `squid -k reconfigure` with no
  instance replaced. This is check-sheet feature 8 and the one thing in this
  module at FULL parity with AWS by way of a mechanism living entirely outside
  Terraform. Also refuses to install an **empty** fetched allowlist, which would
  silently blackhole all egress.
- **The OCI CLI** (`../shared/scripts/install-oci-cli.sh`), which is what the
  two fetch scripts call. Net-new versus GCP, where `gsutil` is preinstalled and
  auto-authenticates.
- **Vector**, from the official Datadog-operated APT repo, tailing
  `/var/log/squid/access.log`, with the `usermod -aG proxy vector` that makes
  that readable and the systemd drop-in that makes Vector actually read
  `vector.toml` rather than its own default `vector.yaml` path.
- **`ufw`**, default-deny incoming, allowing only 22 and `var.squid_port`.

## The build asserts the image works before capturing it

Step 6 of the template reproduces, inside the build, the exact live test the GCP
squid image was validated with by hand on 2026-08-20:

- `squid -k parse` clean against the real config
- `CONNECT <allowed>:443` → **TCP_TUNNEL**, HTTP 200
- `CONNECT <denied>:443` → **TCP_DENIED**, HTTP 403
- `vector` can read `access.log`

then restores the empty allowlist and truncates the logs, so the captured image
grants nothing. A build that fails any of these produces no image at all.

## Build

```bash
cd terraform/oci/packer/build-network
COMPARTMENT_ID=ocid1.compartment.oc1..xxxx ./create.sh

cd ../squid-proxy
cp dev.auto.pkrvars.hcl.example dev.auto.pkrvars.hcl
packer init .
packer validate .
packer build .
```

The image OCID is in `packer-manifest.json` (`builds[].artifact_id`) or from
`oci compute image list --display-name-contains hyperswitch-squid`. That OCID —
**not a name**; OCI has no image-family concept — is what
`values.custom_images.squid` takes.

## Notes

- The build subnet needs outbound internet (apt, the Vector repo, the OCI CLI
  installer, and the self-test's own CONNECT to a real site) and inbound SSH.
- The allowlist is **not** baked in. It comes from
  `hyperswitch-infra:whitelisted-domains/<file>`, uploaded by the unit, fetched
  by cron. Changing it is a config push, not a rebuild.
- `squid.conf.default` here and
  `hyperswitch-infra:terraform/catalog/units/oci/squid-proxy/config/squid.conf`
  are two copies of the same policy in two repositories. Change one, change the
  other — the file itself carries the same warning.
