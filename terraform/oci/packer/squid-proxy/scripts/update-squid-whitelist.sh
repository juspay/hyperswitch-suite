#!/bin/bash
set -euo pipefail

# =============================================================================
# The allowlist hot-reload. This script IS check-sheet feature 8.
# =============================================================================
# Port of terraform/gcp/packer/squid-proxy/scripts/update-squid-whitelist.sh,
# itself a port of the AWS AMI's userdata `update_whitelist.sh` + its
# `*/15 * * * * root /etc/squid/update_whitelist.sh` cron line.
#
# Why it matters more than it looks: everything else about squid-proxy needs an
# instance replacement to change. This does not. The catalog unit uploads
# `allowedlist.txt` to Object Storage on `terragrunt apply`; this script, run
# from /etc/cron.d/squid-whitelist-update every 15 minutes, pulls it and runs
# `squid -k reconfigure` - no instance replaced, no connection dropped. The
# squid-proxy catalog unit's own comment calls this out: "THE ALLOWLIST IS THE
# ONE INPUT HERE THAT CHANGES WITHOUT A ROLLOUT". If this script is missing or
# broken, every allowlist edit silently does nothing, and the failure is
# invisible from the Terraform side because the apply still succeeds.
#
# Auth caveat is identical to fetch-squid-config.sh's: `oci os object get`
# needs an instance principal that does not exist yet, so today this fails soft
# and leaves the (empty, deny-everything) baked-in allowlist in place.
# =============================================================================

IMDS="http://169.254.169.254/opc/v2/instance/metadata"
HDR="Authorization: Bearer Oracle"

md() { curl -sf -H "${HDR}" "${IMDS}/$1" 2>/dev/null | tr -d '"' || true; }

CONFIG_BUCKET=$(md config_bucket)
CONFIG_NAMESPACE=$(md config_namespace)
ALLOWLIST_OBJECT=$(md squid_allowlist_object)
ALLOWLIST_OBJECT="${ALLOWLIST_OBJECT:-allowedlist.txt}"

ALLOWLIST_PATH=/etc/squid/squid.allowed.sites.txt

if [ -z "${CONFIG_BUCKET}" ] || [ -z "${CONFIG_NAMESPACE}" ]; then
  echo "update-squid-whitelist: no config_bucket/config_namespace metadata set, leaving existing allowlist in place" >&2
  exit 0
fi

TMP_FILE=$(mktemp)
trap 'rm -f "${TMP_FILE}"' EXIT

# Tolerate a missing object rather than failing: squid_allowlist_content is an
# optional module input, and `set -e` plus a hard failure here would break this
# cron job on every single run until an object exists. Same reasoning as the
# GCP version's `gsutil -q stat` guard, expressed as a non-fatal get because
# `oci os object get` already returns non-zero on a 404 and there is no need
# for a separate head request.
if ! oci os object get \
      --auth instance_principal \
      --namespace "${CONFIG_NAMESPACE}" \
      --bucket-name "${CONFIG_BUCKET}" \
      --name "${ALLOWLIST_OBJECT}" \
      --file "${TMP_FILE}" >/dev/null 2>&1; then
  echo "update-squid-whitelist: no ${ALLOWLIST_OBJECT} object readable in ${CONFIG_BUCKET} (missing, or no instance principal yet), leaving existing allowlist in place" >&2
  exit 0
fi

# An EMPTY fetched allowlist would silently blackhole all egress. That is the
# correct posture for "we have no allowlist at all" (the baked-in default), but
# it is almost certainly a mistake when it arrives from the bucket, so refuse
# the swap and say so rather than applying it quietly.
if [ ! -s "${TMP_FILE}" ]; then
  echo "update-squid-whitelist: fetched ${ALLOWLIST_OBJECT} is empty, refusing to install it (would deny all egress); keeping the previous allowlist" >&2
  exit 0
fi

if [ -f "${ALLOWLIST_PATH}" ]; then
  cp -a "${ALLOWLIST_PATH}" "${ALLOWLIST_PATH}.old"
fi
install -o proxy -g proxy -m 0644 "${TMP_FILE}" "${ALLOWLIST_PATH}"

# squid.service isn't running yet on the very first (boot-time) invocation of
# this script - Before=squid.service means it runs before squid ever starts, so
# squid.service's own startup naturally reads the file just written above.
# `squid -k reconfigure` against a not-yet-running squid fails ("no running
# copy") and would break the boot-time unit for no reason - only reconfigure a
# squid that is already up, which is the recurring cron case and matches the
# AWS userdata script's behaviour.
if systemctl is-active --quiet squid.service; then
  squid -k reconfigure
fi

echo "update-squid-whitelist: allowlist refreshed at $(date -u +%Y-%m-%dT%H:%M:%SZ) ($(wc -l <"${ALLOWLIST_PATH}") entries)"
