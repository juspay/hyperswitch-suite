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
#
# Download EVERY object in the config bucket - Terraform uploads one object per
# file under the unit's config/ directory - instead of naming files here, so a
# deployment can ship extra files (e.g. Lua scripts that envoy.yaml references)
# without editing this script.
#
# Retry rather than fail once: the objects are uploaded by Terraform, and an
# instance can boot before they land (or before IAM propagates). Without a
# retry the script exits and nothing ever re-runs it, leaving the node with no
# envoy.yaml. Waits up to ~10 minutes for envoy.yaml, then fails loudly.
#
# NOTE THE FILENAME. Envoy picks its config parser from the file EXTENSION:
# a path ending in .yaml is parsed as YAML, anything else falls back to JSON.
# Staging this as "envoy.yaml.new" made Envoy try to parse YAML as JSON and
# fail on the very first character of the leading comment:
#   Unable to parse JSON as proto ... unexpected character: '#'; expected '{'
# so the staged file keeps its .yaml name.
STAGE_DIR="$(mktemp -d /var/tmp/envoy-config.XXXXXX)"
trap 'rm -rf "$STAGE_DIR"' EXIT

fetched=0
for attempt in $(seq 1 40); do
  if /snap/bin/gsutil -m rsync -r "gs://${BUCKET}" "$STAGE_DIR" && [ -f "$STAGE_DIR/envoy.yaml" ]; then
    fetched=1
    break
  fi
  echo "envoy-startup: gs://${BUCKET}/envoy.yaml not available yet (attempt ${attempt}/40), retrying in 15s" >&2
  sleep 15
done
if [ "$fetched" != 1 ]; then
  echo "envoy-startup: gs://${BUCKET} has no envoy.yaml after 40 attempts" >&2
  exit 1
fi

# Every file other than the two with a dedicated destination below lands under
# /etc/envoy keeping its relative path. They go in first because envoy.yaml may
# reference them.
while IFS= read -r -d '' f; do
  rel="${f#"$STAGE_DIR"/}"
  case "$rel" in
    envoy.yaml | vector.toml) continue ;;
  esac
  install -D -o envoy -g envoy -m 0644 "$f" "/etc/envoy/$rel"
done < <(find "$STAGE_DIR" -type f -print0)

# Validate before swapping in, so a bad config leaves the previous one intact
# rather than putting the node into the same crash loop this script exists to
# fix.
if /usr/bin/envoy --mode validate -c "$STAGE_DIR/envoy.yaml"; then
  install -o envoy -g envoy -m 0644 "$STAGE_DIR/envoy.yaml" /etc/envoy/envoy.yaml
else
  echo "envoy-startup: fetched config failed validation, not applying" >&2
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
if [ -f "$STAGE_DIR/vector.toml" ]; then
  VSTAGE=/etc/vector/vector.staging.toml
  cp "$STAGE_DIR/vector.toml" "$VSTAGE"
  if /usr/bin/vector validate "$VSTAGE"; then
    mv "$VSTAGE" /etc/vector/vector.toml
    chown root:vector /etc/vector/vector.toml
    chmod 640 /etc/vector/vector.toml
  else
    echo "envoy-startup: fetched vector.toml failed validation, not applying" >&2
    rm -f "$VSTAGE"
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
