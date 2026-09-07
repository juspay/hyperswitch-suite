#!/bin/bash
set -euo pipefail

# Boot-time config delivery for the Dante SOCKS5 proxy, mirroring
# ../../squid-proxy/scripts/fetch-squid-config.sh.
#
# The composition module writes danted.conf into a GCS bucket and passes the
# bucket name via instance metadata key "config-bucket". If no object is
# published, a default config is rendered locally instead - so the image is
# usable on its own and the live layer only overrides when it needs to.

md() {
  # -f is required: a missing metadata attribute returns HTTP 404 with an HTML
  # body, and without --fail curl exits 0 and prints that HTML as the value.
  curl -sf -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$1" || true
}

CONFIG_BUCKET="$(md config-bucket)"
SOCKS5_PORT="$(md socks5-port)"
SOCKS5_PORT="${SOCKS5_PORT:-1080}"

if [ -n "$CONFIG_BUCKET" ] && gsutil -q stat "gs://${CONFIG_BUCKET}/danted.conf" 2>/dev/null; then
  echo "fetch-socks5-config: using danted.conf from gs://${CONFIG_BUCKET}" >&2
  gsutil cp "gs://${CONFIG_BUCKET}/danted.conf" /etc/danted.conf
else
  # Dante's `external:` must name a real interface or address; it does not
  # accept 0.0.0.0. On GCE the primary NIC is conventionally ens4, but that is
  # not guaranteed across image families - resolve it from the default route
  # instead of hardcoding.
  EXTERNAL_IF="$(ip -o -4 route show to default | awk '{print $5}' | head -1)"
  if [ -z "$EXTERNAL_IF" ]; then
    echo "fetch-socks5-config: could not determine the default-route interface" >&2
    exit 1
  fi

  echo "fetch-socks5-config: no published config, rendering default on ${EXTERNAL_IF}:${SOCKS5_PORT}" >&2

  # No authentication: this proxy is reachable only through an internal load
  # balancer whose source ranges are pinned by the composition module, plus a
  # VPC firewall rule. SOCKS5 username/password (RFC 1929) travels in
  # cleartext, so it would add little on top of the network ACL. Publish a
  # danted.conf via the module's socks5_config_content to change that.
  cat > /etc/danted.conf <<EOF
logoutput: /var/log/danted.log

internal: 0.0.0.0 port = ${SOCKS5_PORT}
external: ${EXTERNAL_IF}

socksmethod: none
clientmethod: none

user.privileged: root
user.unprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: connect
    log: connect disconnect error
}
EOF
fi

touch /var/log/danted.log
chown nobody:nogroup /var/log/danted.log || true

# --no-block for the same reason fetch-squid-config.sh uses it: this unit
# carries Before=danted.service, and a blocking restart deadlocks against that
# ordering constraint. At boot danted.service has not started yet and reads the
# file written above on its own; this only matters when the unit is
# re-triggered on a running instance.
if systemctl is-active --quiet danted.service; then
  systemctl restart --no-block danted.service
fi
