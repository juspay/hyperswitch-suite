# Envoy GCE image (Packer)

Builds the custom image the `envoy-proxy` composition module's `envoy_image`
input expects (`../../modules/composition/envoy-proxy/variables.tf`). GCP's
managed-instance-group model has no
userdata-only path the way AWS's ASG + `custom_userdata` does (see
`terraform/aws/modules/composition/envoy-proxy` and the AWS live layer's
`templates/userdata.sh` in `hyperswitch-infra`, which only ever template
config into an *already-installed* Envoy) — the binary has to be baked into
the image itself.

What this builds, on top of a stock `ubuntu-2204-lts` image:

- Envoy, extracted from the **official** `envoyproxy/envoy` Docker image
  (published by the Envoy project's own org — verified against Docker Hub's
  API before use), pinned to `var.envoy_version` (default `v1.39.0`).
  `docker.io` is installed only for this extraction step and removed again
  in the cleanup step — Envoy runs as a native systemd service at runtime,
  not a container. Three other routes were tried first and rejected — see
  the provisioner comment in `envoy-image.pkr.hcl` for the full history:
  `apt.envoyproxy.io` (Envoy's own apt repo, explicitly documented as
  unmaintained), the older Tetrate `getenvoy-package` apt repo
  (`deb.dl.getenvoy.io`, no package for Ubuntu jammy), and Tetrate's binary
  archive (`archive.tetratelabs.io` — worked, but is a third-party
  redistribution one hop further from the source, with no checksum to
  verify against).
- `ufw`, default-deny incoming, with SSH (22), the Envoy http/https/mtls
  ports, and Vector's Prometheus exporter port explicitly allowed — defense
  in depth on top of the VPC-level firewall rules, matching the host-level
  lockdown the AWS AMI/userdata pattern also does
- an `envoy` system user, `/etc/envoy`, `/var/log/envoy`
- `envoy.service` — runs Envoy against `/etc/envoy/envoy.yaml`,
  `Restart=on-failure`. **No config-fetch systemd unit and no default
  envoy.yaml are baked in** — same as the AWS AMI, this service assumes
  something else places a real config there and restarts it; on a fresh
  boot with nothing else wiring that up, it will crash-loop until something
  does (see "Config delivery" below).
- Vector (`vector.service`, apt package from the official
  `setup.vector.dev`/Datadog-operated repo), with a baked-in *default*
  `/etc/vector/vector.toml` (`scripts/vector.toml`, adapted from the AWS
  fleet's canonical config with AWS-only sinks removed) as a fallback for
  instances that never get a live-layer override, plus a systemd drop-in
  (`vector.service.d/gcp-overrides.conf`) that fixes a real, image-level bug
  in this Vector package build: the shipped unit's `ExecStartPre`/
  `ExecStart` pass no config path at all, so Vector silently falls back to
  its own default `/etc/vector/vector.yaml` instead of ours — see that
  file's own comment for the fix and a real CLI asymmetry it documents
  (`vector validate` takes the config path as a bare positional argument,
  unlike the daemon's `-c`/`--config`).

## Config delivery — moved to the live layer (2026-08-20)

Earlier builds of this image baked config-fetch logic directly into the
image (`envoy-config-fetch.service`, `vector-config-fetch.service`,
`gce-metadata.service`, all pulling from the GCS config bucket via a
`config-bucket` instance-metadata key). That's been removed: **pulling
envoy.yaml/vector.toml from the config bucket and restarting the services is
now the consuming live-layer unit's job**, via a GCE startup-script wired
through the composition module's `custom_startup_script` variable — exactly
mirroring the AWS AMI + `templates/userdata.sh` split (see that file in
`hyperswitch-infra`'s AWS sandbox `envoy-proxy` live-layer unit, and the GCP
equivalent at `hyperswitch-infra/terraform/gcp/live/dev/asia-south1/
envoy-proxy/templates/startup-script.sh`).

This image on its own now only ships plain, static-config-reading systemd
units — same as the AWS AMI — with no assumption baked in about *where*
that config comes from. Changing the fetch/orchestration logic no longer
requires a Packer rebuild; it's a live-layer script edit instead, the same
tradeoff AWS already has.

## Build

```bash
cd terraform/gcp/packer/envoy-proxy
cp dev.auto.pkrvars.hcl.example dev.auto.pkrvars.hcl   # fill in project_id/zone/network/subnetwork
packer init .
packer validate .
packer build .
```

The built image's self-link (via `packer-manifest.json`, or
`gcloud compute images describe <name>`) is what a live-layer `envoy-proxy`
unit passes as `envoy_image`.

## Notes

- `subnetwork` needs egress to the internet (Cloud NAT) during the build —
  the shell provisioner runs `apt-get` (for `docker.io` and `ufw`) and
  `docker pull` against Docker Hub.
- `envoy_version` is an Envoy release tag (e.g. `v1.39.0`), not an apt
  package version — check https://hub.docker.com/r/envoyproxy/envoy/tags
  for available tags before bumping it.
- This is intentionally minimal (Vector is included, but no
  CloudWatch/Wazuh equivalents the AWS AMI's userdata layers on) — add
  environment-specific hardening/observability provisioners here as GCP
  envoy actually goes live, the same way `hyperswitch-infra`'s AWS live
  layers add environment-specific userdata on top of a generic AMI (and, on
  the GCP side, the same way the live-layer startup-script is now the place
  for that kind of per-environment logic — see "Config delivery" above).
