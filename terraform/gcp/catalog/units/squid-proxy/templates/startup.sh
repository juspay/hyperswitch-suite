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

fetch() { # object, destination
  if ! /snap/bin/gsutil cp "gs://${BUCKET}/$1" "$2.new"; then
    echo "squid-startup: failed to fetch gs://${BUCKET}/$1" >&2
    return 1
  fi
  mv "$2.new" "$2"
}

# The allowlist must land BEFORE squid.conf is validated: squid refuses to
# start when an acl references a file that does not exist, so a missing
# allowlist would break Squid rather than merely denying traffic.
fetch allowedlist.txt /etc/squid/allowedlist.txt
fetch squid.conf      /etc/squid/squid.conf

# Validate before restarting, so a bad config leaves the previous (working)
# one running instead of taking the whole egress path down.
if ! squid -k parse -f /etc/squid/squid.conf; then
  echo "squid-startup: fetched config failed validation, not restarting" >&2
  exit 1
fi

systemctl enable squid.service
systemctl restart squid.service
