# Squid GCE image (Packer)

Builds the custom image the `squid-proxy` composition module's `squid_image`
input expects (`../../modules/composition/squid-proxy/variables.tf`) — same
reason as `../envoy-proxy`: GCP's managed-instance-group model has no
userdata-only path the way AWS's ASG + `custom_userdata` does (see
`terraform/aws/live/sandbox/ap-south-1/squid-proxy` in `hyperswitch-infra`,
which only ever templates config into an *already-installed* Squid), so the
binary has to be baked into the image itself.

Kept intentionally minimal, unlike the AWS sandbox's userdata (no Wazuh
agent, no CloudWatch agent, no vector log shipping, no S3-synced whitelist
cron) — add environment-specific pieces here as GCP Squid actually goes
live, same as `../envoy-proxy`'s README notes for Envoy.

What this builds, on top of a stock `ubuntu-2204-lts` image:

- `squid`, installed from the Ubuntu apt repo
- `squid-config-fetch.service` — a oneshot unit that pulls `squid.conf` from
  the GCS bucket the composition module already creates and passes via the
  `config-bucket` instance-metadata key
  (`../../modules/composition/squid-proxy/main.tf`), then restarts Squid
- Squid's own `squid.service` (shipped by the apt package) enabled to start
  after config-fetch

## Build

```bash
cd terraform/gcp/packer/squid-proxy
cp dev.auto.pkrvars.hcl.example dev.auto.pkrvars.hcl   # fill in project_id/zone/network/subnetwork
packer init .
packer validate .
packer build .
```

The built image's self-link (via `packer-manifest.json`, or
`gcloud compute images describe <name>`) is what a live-layer `squid-proxy`
unit passes as `squid_image`.

## Notes

- `subnetwork` needs egress to the internet (Cloud NAT) during the build —
  the shell provisioner runs `apt-get`.
- The allowed-domains list (`squid.conf`'s `acl allowed_http_sites` /
  `allowed_https_sites`) is not baked into the image — it's part of
  `squid_config_content`, rendered by the composition module into the
  config bucket, so it can change without a rebuild.
- `use_iap = true` (the default) is currently broken for Ubuntu source
  images — `hashicorp/packer#12169`: the IAP tunnel connects but the SSH
  handshake never completes. Set `use_iap = false` to build over a
  temporary public IP instead; this requires
  `hyperswitch-infra/terraform/gcp/live/dev/asia-south1/envoy-packer-temp-ssh-firewall`
  (a tag-based firewall rule shared with the Envoy build, not
  Envoy-specific despite the directory name) to be applied first, and your
  build machine's egress IP to be one of its allowed VPN source ranges.
