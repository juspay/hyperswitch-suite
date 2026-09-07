#!/bin/bash
# GCP equivalent of ../../../../aws/live/sandbox/ap-south-1/squid-proxy/
# templates/userdata.sh - unlike that AWS script (and unlike this repo's own
# ../../envoy-proxy/templates/startup-script.sh), this does NOT fetch
# squid.conf or the domain whitelist - the squid-proxy Packer image already
# bakes in squid-config-fetch.service/squid-whitelist-fetch.service
# (Before=squid.service) for those, plus a whitelist-refresh cron
# (update-squid-whitelist.sh, every 15 min) - duplicating that here would
# just be two mechanisms racing to write the same files. See this unit's
# terragrunt.hcl and the squid-proxy module's variables.tf
# (custom_startup_script's own description) for the full reasoning.
#
# What this DOES do: fetch vector.toml from the config bucket, same pattern
# as envoy's own startup-script.sh - the Packer image bakes its own
# vector.toml in at BUILD time only (scripts/vector.toml.pkrtpl.hcl), with
# no boot-time override path otherwise. Runs as a GCE startup-script
# (metadata_startup_script) on every boot, not just the first.
set -e
set -x

MD_FLAVOR_HEADER="Metadata-Flavor: Google"
MD_BASE="http://metadata.google.internal/computeMetadata/v1/instance"

fetch_meta() {
  curl -sf -H "$MD_FLAVOR_HEADER" "$1" || echo ""
}

CONFIG_BUCKET=$(fetch_meta "${MD_BASE}/attributes/config-bucket")

if [ -z "$CONFIG_BUCKET" ]; then
  echo "startup-script: no config-bucket metadata set, leaving existing config in place"
  exit 0
fi

# ------------------------------ Vector config ------------------------------ #
# Optional - a fleet can run without a live-layer vector.toml override and
# just use the image's own baked-in default (this is the current dev
# posture: vector_config_content is unset in this unit's terragrunt.hcl, so
# no object exists at this path and this block is a no-op).
if gsutil -q stat "gs://${CONFIG_BUCKET}/vector.toml"; then
  gsutil cp "gs://${CONFIG_BUCKET}/vector.toml" /etc/vector/vector.toml
  chown root:vector /etc/vector/vector.toml
  chmod 640 /etc/vector/vector.toml

  # ---------------------- Instance metadata for Vector --------------------- #
  # Same METADATA_* env-var pattern as ../../envoy-proxy/templates/
  # startup-script.sh - only meaningful if a live-layer vector.toml override
  # actually references get_env_var("METADATA_*") the way envoy's does; the
  # image's own default vector.toml doesn't, so this drop-in is harmless
  # either way.
  INSTANCE_ID=$(fetch_meta "${MD_BASE}/id")
  INSTANCE_IP=$(fetch_meta "${MD_BASE}/network-interfaces/0/ip")
  CREATED_BY=$(fetch_meta "${MD_BASE}/attributes/created-by")
  INSTANCE_TEMPLATE=$(fetch_meta "${MD_BASE}/attributes/instance-template")
  ASG_NAME="${CREATED_BY##*/}"
  LT_VERSION="${INSTANCE_TEMPLATE##*/}"

  cat > /etc/default/metadata <<EOF
METADATA_INSTANCE_ID=${INSTANCE_ID:-unknown}
METADATA_INSTANCE_IP=${INSTANCE_IP:-unknown}
METADATA_ASG_NAME=${ASG_NAME:-unknown}
METADATA_LT_VERSION=${LT_VERSION:-unknown}
EOF

  mkdir -p /etc/systemd/system/vector.service.d
  cat > /etc/systemd/system/vector.service.d/environment.conf <<EOF
[Service]
EnvironmentFile=-/etc/default/metadata
EOF

  systemctl daemon-reload
  systemctl restart vector.service
fi
