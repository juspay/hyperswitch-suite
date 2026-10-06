#!/usr/bin/env bash
# Fetches squid.conf + allowedlist.txt from the GCS config bucket and restarts
# Squid.
#
# WHY THIS EXISTS. Same gap as the Envoy tier: the baked image ships Squid and
# a stock /etc/squid/squid.conf, but nothing in the image ever pulls the real
# config from the bucket named in the instance's `config-bucket` metadata. The
# stock config ends in `http_access deny all`, so every proxied request hangs
# until the client times out and the egress path appears broken.
set -euo pipefail

BUCKET="$(curl -sS -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/config-bucket)"

install -d /etc/squid

# Download EVERY object in the config bucket - Terraform uploads one object per
# file (squid.conf, allowedlist.txt and anything in additional_config_files_path)
# - instead of naming files here, so a deployment can ship extra files that
# squid.conf references (extra ACL lists, error pages) without editing this
# script.
#
# Retry rather than fail once: the objects are uploaded by Terraform, and an
# instance can boot before they land (or before IAM propagates). Without a
# retry the script exits and nothing re-runs it, leaving Squid on the stock
# `http_access deny all` config. Waits up to ~10 minutes for squid.conf, then
# fails loudly.
STAGE_DIR="$(mktemp -d /var/tmp/squid-config.XXXXXX)"
trap 'rm -rf "$STAGE_DIR"' EXIT

fetched=0
for attempt in $(seq 1 40); do
  if /snap/bin/gsutil -m rsync -r "gs://${BUCKET}" "$STAGE_DIR" \
    && [ -f "$STAGE_DIR/squid.conf" ] && [ -f "$STAGE_DIR/allowedlist.txt" ]; then
    fetched=1
    break
  fi
  echo "squid-startup: gs://${BUCKET} is missing squid.conf/allowedlist.txt (attempt ${attempt}/40), retrying in 15s" >&2
  sleep 15
done
if [ "$fetched" != 1 ]; then
  echo "squid-startup: gs://${BUCKET} has no squid.conf/allowedlist.txt after 40 attempts" >&2
  exit 1
fi

# Every file lands under /etc/squid keeping its relative path. They are all
# placed BEFORE squid.conf is validated: squid refuses to start when an acl
# references a file that does not exist, so a missing allowlist would break
# Squid rather than merely denying traffic. vector.toml is not delivered by this
# script (the image owns Vector's config), so it is skipped.
while IFS= read -r -d '' f; do
  rel="${f#"$STAGE_DIR"/}"
  case "$rel" in
    vector.toml) continue ;;
  esac
  install -D -m 0644 "$f" "/etc/squid/$rel"
done < <(find "$STAGE_DIR" -type f -print0)

# Validate before restarting, so a bad config leaves the previous (working)
# one running instead of taking the whole egress path down.
if ! squid -k parse -f /etc/squid/squid.conf; then
  echo "squid-startup: fetched config failed validation, not restarting" >&2
  exit 1
fi

systemctl enable squid.service
systemctl restart squid.service
