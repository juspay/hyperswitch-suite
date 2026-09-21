#!/usr/bin/env bash
# Fetches Envoy's config from the GCS config bucket and starts Envoy.
#
# WHY THIS EXISTS. The custom Envoy image bakes in envoy.service, which runs
#   /usr/bin/envoy -c /etc/envoy/envoy.yaml
# but nothing in the image creates that file - no config-fetch step ships in
# the baked image. Without it: "Invalid path: /etc/envoy/envoy.yaml",
# envoy.service restarting every 5s, and the GCLB backend permanently
# UNHEALTHY. This script closes that gap from the instance-template side, so
# no image rebuild is needed.
#
# Idempotent and safe to re-run: it re-fetches on every boot, so rolling the
# MIG is all that is needed to pick up a new config.
set -euo pipefail

BUCKET="$(curl -sS -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/config-bucket)"

install -d -o envoy -g envoy /etc/envoy /var/log/envoy

# The instance service account has objectViewer on this bucket (granted by the
# module); if this 403s or 404s, do NOT start Envoy with a stale/absent config.
# NOTE THE FILENAME. Envoy picks its config parser from the file EXTENSION:
# a path ending in .yaml is parsed as YAML, anything else falls back to JSON.
# Staging this as "envoy.yaml.new" made Envoy try to parse YAML as JSON and
# fail on the very first character of the leading comment:
#   Unable to parse JSON as proto ... unexpected character: '#'; expected '{'
# so the staging file must itself end in .yaml.
STAGE=/etc/envoy/envoy.staging.yaml

if ! /snap/bin/gsutil cp "gs://${BUCKET}/envoy.yaml" "$STAGE"; then
  echo "envoy-startup: failed to fetch gs://${BUCKET}/envoy.yaml" >&2
  exit 1
fi

# Validate before swapping in, so a bad config leaves the previous one intact
# rather than putting the node into the same crash loop this script exists to
# fix.
if /usr/bin/envoy --mode validate -c "$STAGE"; then
  mv "$STAGE" /etc/envoy/envoy.yaml
  chown envoy:envoy /etc/envoy/envoy.yaml
else
  echo "envoy-startup: fetched config failed validation, not applying" >&2
  rm -f "$STAGE"
  exit 1
fi

# `envoy --mode validate` runs as root and leaves behind a root-owned
# access-log file, which the real envoy.service (User=envoy) then fails to
# open - re-own unconditionally rather than one hardcoded filename.
chown -R envoy:envoy /var/log/envoy

systemctl daemon-reload
systemctl enable envoy.service
systemctl restart envoy.service

# Vector is optional - the image bakes in a working default vector.toml, so
# a fleet with none in the config bucket still ships logs/metrics fine. This
# lets a deployment override that default without rebuilding the image.
if /snap/bin/gsutil -q stat "gs://${BUCKET}/vector.toml"; then
  VSTAGE=/etc/vector/vector.staging.toml
  if /snap/bin/gsutil cp "gs://${BUCKET}/vector.toml" "$VSTAGE"; then
    if /usr/bin/vector validate "$VSTAGE"; then
      mv "$VSTAGE" /etc/vector/vector.toml
      chown root:vector /etc/vector/vector.toml
      chmod 640 /etc/vector/vector.toml
    else
      echo "envoy-startup: fetched vector.toml failed validation, not applying" >&2
      rm -f "$VSTAGE"
    fi
  else
    echo "envoy-startup: failed to fetch gs://${BUCKET}/vector.toml, keeping the image's baked-in default" >&2
  fi
fi

# Feeds vector.toml's get_env_var("METADATA_*") calls - the owning MIG's
# name (the "created-by" attribute) and the instance template name.
MD_BASE="http://metadata.google.internal/computeMetadata/v1/instance"
fetch_meta() { curl -sS -H 'Metadata-Flavor: Google' "$1" || true; }

INSTANCE_ID="$(fetch_meta "${MD_BASE}/id")"
INSTANCE_IP="$(fetch_meta "${MD_BASE}/network-interfaces/0/ip")"
CREATED_BY="$(fetch_meta "${MD_BASE}/attributes/created-by")"
INSTANCE_TEMPLATE="$(fetch_meta "${MD_BASE}/attributes/instance-template")"

cat > /etc/default/metadata <<EOF
METADATA_INSTANCE_ID=${INSTANCE_ID:-unknown}
METADATA_INSTANCE_IP=${INSTANCE_IP:-unknown}
METADATA_ASG_NAME=${CREATED_BY##*/}
METADATA_LT_VERSION=${INSTANCE_TEMPLATE##*/}
EOF

mkdir -p /etc/systemd/system/vector.service.d
cat > /etc/systemd/system/vector.service.d/environment.conf <<EOF
[Service]
EnvironmentFile=-/etc/default/metadata
EOF

systemctl daemon-reload
systemctl restart vector.service
