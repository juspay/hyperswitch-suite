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

systemctl daemon-reload
systemctl enable envoy.service
systemctl restart envoy.service
