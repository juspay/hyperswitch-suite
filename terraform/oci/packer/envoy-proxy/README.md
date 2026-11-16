# Envoy custom image (OCI, Packer)

Builds the image the `envoy-proxy` composition module's `image_id` input expects
(`../../modules/composition/envoy-proxy/variables.tf`), passed through by
`hyperswitch-infra:terraform/catalog/units/oci/envoy-proxy` from
`values.custom_images.envoy`.

That unit has **no fallback default** for `image_id` — no `try(…,
"PLACEHOLDER-envoy")` — so it fails loudly at plan time if no real image exists.
This directory is the other half of that contract.

Ported from [`../../../gcp/packer/envoy-proxy/`](../../../gcp/packer/envoy-proxy).

## What this builds, on top of a stock `Canonical-Ubuntu-26.04` platform image

- **Envoy**, extracted from the **official** `envoyproxy/envoy` Docker image,
  pinned by **content digest** (`var.envoy_image_digest`, currently the digest
  of tag `var.envoy_version` = v1.39.0; the tag is kept for humans). `docker.io`
  is installed only to perform the extraction and purged in the cleanup step —
  Envoy runs as a native systemd service, not a container. Three other install
  routes were tried and rejected during the GCP port (Envoy's own unmaintained
  apt repo, Tetrate's archived `getenvoy-package` repo, Tetrate's checksum-less
  binary archive); all three rejections are about upstream packaging and carry
  over unchanged.
- **`envoy.service`**, running as the `envoy` user against
  `/etc/envoy/envoy.yaml`, `Restart=on-failure`.
- **A baked-in default `envoy.yaml`** (`scripts/envoy.yaml.default`) that
  answers **503 to every request, including the health check path**, with a body
  saying why. See below — this is the sharpest divergence from GCP in the whole
  port.
- **`envoy-config-fetch.service`** — oneshot, `Before=envoy.service`, pulls
  `envoy.yaml` (and optionally `vector.toml`) from Object Storage and
  **validates with `envoy --mode validate` before installing**.
- **`oci-metadata.service`** — writes `/etc/default/metadata` from IMDS so
  `vector.toml`'s `get_env_var("METADATA_*")` calls resolve.
- **The OCI CLI** (`../shared/scripts/install-oci-cli.sh`).
- **Vector**, with the systemd drop-in that points it at `vector.toml` and feeds
  it `/etc/default/metadata`.
- **`ufw`**, default-deny incoming, allowing 22, the Envoy http/https/mTLS
  ports and Vector's Prometheus port — and **not** the Envoy admin port.

## Why this image bakes in a config when the GCP one deliberately does not

GCP's envoy image ships no `envoy.yaml` on purpose. Its README records the
decision and the date: config delivery *"moved to the live layer (2026-08-20)…
pulling envoy.yaml/vector.toml from the config bucket and restarting the
services is now the consuming live-layer unit's job, via a GCE startup-script
wired through the composition module's `custom_startup_script` variable"*. On
GCP a real config therefore arrives seconds after boot, and a brief crash loop
is a fine way to spend that time.

**That seam does not exist on OCI.** The OCI composition module has no
`custom_startup_script`; it has `custom_user_data`, which the catalog unit does
not set, and it instead pushes `config_bucket` / `config_namespace` through
instance metadata — a statement that the *image* is expected to fetch. Its squid
sibling says so outright in `locals.tf`: *"The image's boot script and its
15-minute refresh timer read these off the metadata service."*

Combined with the fact that the fetch **cannot succeed today** (no instance
principal — see below), a no-default image on OCI would mean a permanent
systemd crash loop on every instance in the fleet, burying any real error in
restart noise.

So the default exists, and it answers 503 to everything. That is a deliberate
choice between two failure modes:

| Option | Consequence |
|---|---|
| No config → crash loop | Fleet never registers; `systemctl status` is a wall of restarts |
| Default answering **200** on `/health` | Load balancer reports a healthy fleet that black-holes traffic — **the worst outcome** |
| Default answering **503** on everything | Instances register, fail health checks, take no traffic, and say why in the response body |

The build asserts the 503 (and the body text) rather than trusting it, so a
future edit that accidentally makes the placeholder look healthy fails the
build.

## The build asserts the image works before capturing it

Step 8 of the template checks, on the live build instance:

- `envoy.service` reaches `active`
- admin `/ready` returns **200** on loopback
- `/stats/prometheus` is scrapeable (what `vector.toml` depends on)
- the admin listener is bound to **127.0.0.1 only**, checked against the real
  socket via `ss`, not against the config file
- the data-plane port answers **503** with the placeholder body
- `vector` can read the Envoy log directory

A build failing any of these produces no image.

## Build

```bash
cd terraform/oci/packer/build-network
COMPARTMENT_ID=ocid1.compartment.oc1..xxxx ./create.sh

cd ../envoy-proxy
cp dev.auto.pkrvars.hcl.example dev.auto.pkrvars.hcl
packer init .
packer validate .
packer build .
```

The image OCID is in `packer-manifest.json` (`builds[].artifact_id`). OCI has no
image-family concept, so `values.custom_images.envoy` takes a literal OCID.

## Mirror Envoy into OCIR (control 8a, internal registry only)

Section 8a of the hardening procedure requires internal registries only: the
Envoy binary must come from OCIR, not pulled directly from Docker Hub at build
time. This is a **manual pre-build step** — the build VM has an outbound path to
Docker Hub and PyPI but typically no push credentials for OCIR, so the mirror
is not wired into the Packer template.

```bash
# From a machine with Docker Hub and OCIR credentials:
docker pull envoyproxy/envoy@${var.envoy_image_digest}
docker tag envoyproxy/envoy@${var.envoy_image_digest} \
  ap-mumbai-1.ocir.io/<namespace>/dev/hyperswitch/envoy:v1.39.0
docker push ap-mumbai-1.ocir.io/<namespace>/dev/hyperswitch/envoy:v1.39.0
```

Before the first build, replace the `<namespace>` placeholder with the real
tenancy namespace and confirm the tag, then change the Step 2 pull in
`envoy-image.pkr.hcl` to reference the OCIR mirror instead of
`envoyproxy/envoy@${var.envoy_image_digest}`.

## Notes

- The build subnet needs outbound internet: `apt`, Docker Hub, the Vector repo
  and the OCI CLI installer are all reached during the build.
- `envoy_version` is a Docker Hub tag on `envoyproxy/envoy`, not an apt version.
- `var.envoy_http_port` must match the `envoy-proxy` unit's `backend_port`. They
  are both 8080 today; a mismatch surfaces as a permanently unhealthy backend
  set, not as an error.
- Kept intentionally minimal, like the GCP image — Vector is included, but none
  of the CloudWatch/Wazuh layers the AWS AMI's userdata adds.
