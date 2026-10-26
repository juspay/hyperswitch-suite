#!/bin/bash
set -euo pipefail

# GCP equivalent of the AWS AMI's userdata.sh `update_whitelist.sh` cron
# job. The composition module (../../main.tf) optionally writes a
# whitelist object into the same config bucket squid.conf comes from, and
# passes the bucket name via instance metadata key "config-bucket" (same
# key fetch-squid-config.sh reads). Run once at boot, before squid starts
# (via squid-whitelist-fetch.service), and then periodically via cron
# (/etc/cron.d/squid-whitelist-update) so a whitelist edit takes effect
# without an instance replacement/refresh.
CONFIG_BUCKET=$(curl -sf -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/attributes/config-bucket" || true)

if [ -z "$CONFIG_BUCKET" ]; then
  echo "update-squid-whitelist: no config-bucket metadata set, leaving existing whitelist in place" >&2
  exit 0
fi

# Tolerate a missing allowedlist.txt object (squid_allowlist_content is an
# optional module input) rather than failing - `gsutil cp` on a
# nonexistent object exits non-zero, which would otherwise fail this
# script under `set -e` on every single cron run until an object exists.
if ! gsutil -q stat "gs://${CONFIG_BUCKET}/allowedlist.txt"; then
  echo "update-squid-whitelist: no allowedlist.txt object in bucket, leaving existing whitelist in place" >&2
  exit 0
fi

TMP_FILE=$(mktemp)
gsutil cp "gs://${CONFIG_BUCKET}/allowedlist.txt" "$TMP_FILE"

if [ -f /etc/squid/squid.allowed.sites.txt ]; then
  cp /etc/squid/squid.allowed.sites.txt /etc/squid/squid.allowed.sites.txt.old
fi
mv "$TMP_FILE" /etc/squid/squid.allowed.sites.txt
chown proxy:proxy /etc/squid/squid.allowed.sites.txt

# squid.service isn't running yet on the very first (boot-time) invocation
# of this script - Before=squid.service means it runs before squid ever
# starts, so squid.service's own startup naturally reads the file just
# written above. `squid -k reconfigure` against a not-yet-running squid
# fails ("no running copy") and would break the boot-time unit for no
# reason - only reconfigure a squid that's already up (the recurring cron
# case, matching the AWS userdata script's `squid -k reconfigure` after
# every whitelist pull).
if systemctl is-active --quiet squid.service; then
  squid -k reconfigure
fi

echo "update-squid-whitelist: whitelist refreshed at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
