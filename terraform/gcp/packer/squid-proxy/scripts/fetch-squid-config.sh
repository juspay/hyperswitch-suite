#!/bin/bash
set -euo pipefail

# GCP equivalent of the AWS AMI's userdata `aws s3 cp .../squid.conf` step.
# The composition module (../../main.tf) writes the rendered config to a GCS
# bucket and passes its name via instance metadata key "config-bucket".
#
# -f (--fail) is required: a missing metadata attribute returns HTTP 404
# with a real HTML body (confirmed via a live smoke test on
# hyperswitch-squid-dev-20260819193344 - GCP's metadata server no longer
# returns a bare-text 404 the way older docs describe). Without -f, curl
# exits 0 and prints that HTML into $CONFIG_BUCKET, so the empty-string
# check below never fires and the script instead fails hard trying
# `gsutil cp gs://<html>/squid.conf`.
CONFIG_BUCKET=$(curl -sf -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/attributes/config-bucket" || true)

if [ -z "$CONFIG_BUCKET" ]; then
  echo "fetch-squid-config: no config-bucket metadata set, leaving existing /etc/squid/squid.conf in place" >&2
  exit 0
fi

gsutil cp "gs://${CONFIG_BUCKET}/squid.conf" /etc/squid/squid.conf

# squid.service isn't running yet on the normal boot-time invocation of
# this script - squid-config-fetch.service has Before=squid.service, so
# squid.service starts fresh right after this script exits and reads the
# config just written above on its own; no restart needed there.
#
# A plain `systemctl restart squid.service` here is unsafe in ANY
# invocation of this script, not just at boot: this unit carries
# Before=squid.service, and that ordering constraint is enforced against
# whatever job this script's own `systemctl restart` call schedules for
# squid.service too - a BLOCKING restart call deadlocks systemd (this
# unit's start job can't finish until the restart job completes, but the
# restart job is itself held behind this unit's own Before= ordering).
# Confirmed via two separate live hangs: once at boot (squid.service not
# yet running), and again when manually re-triggering this unit via
# `systemctl restart squid-config-fetch.service` on an already-running
# instance (squid.service WAS active that time - an is-active guard
# alone does not avoid this, only --no-block does). `--no-block` queues
# the restart without waiting for it, sidestepping the ordering deadlock
# entirely regardless of squid's current state or when this script runs.
if systemctl is-active --quiet squid.service; then
  systemctl restart --no-block squid.service
fi
