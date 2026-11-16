#!/bin/bash
set -euo pipefail

# =============================================================================
# OCI equivalent of the AWS AMI's userdata `aws s3 cp .../squid.conf` step, and
# of the GCP image's `gsutil cp gs://<bucket>/squid.conf`.
# =============================================================================
# THE ONLY THING THAT CHANGED IN THE PORT IS THE FETCH MECHANISM. The ordering
# contract, the systemd deadlock avoidance and the fail-soft behaviour are
# carried over verbatim from terraform/gcp/packer/squid-proxy/scripts/
# fetch-squid-config.sh, because all three were learned from real live failures
# on GCP and none of them is cloud-specific.
#
# Metadata contract, set by terraform/oci/modules/composition/squid-proxy's
# locals.tf `base_metadata`:
#     config_bucket          bucket name        ("" when create_config_bucket=false)
#     config_namespace       Object Storage namespace
#     squid_config_object    object name        (default "squid.conf")
#     squid_allowlist_object object name        (read by the sibling script)
#     squid_port
# A rename on either side silently breaks the config pull - that module's
# locals.tf carries the same warning next to the keys.
#
# TWO REAL DIFFERENCES FROM GCP, both forced by OCI and both deliberate:
#
#   1. OCI's Object Storage path needs a NAMESPACE as well as a bucket name -
#      `gs://<bucket>/<object>` has no namespace component, `oci os object get`
#      requires one. Hence the second metadata key.
#
#   2. AUTHENTICATION IS NOT FREE HERE, AND TODAY IT DOES NOT EXIST.
#      `gsutil` on GCE authenticates automatically as the instance's attached
#      service account. OCI's equivalent is an instance principal, which
#      requires the instance to be a member of an `oci_identity_dynamic_group`
#      and for an `oci_identity_policy` to grant that group
#      `read objects in ...`. The squid-proxy composition module deliberately
#      creates NEITHER (see its README, "Not yet implemented, deliberately:
#      Identity" - the design is owned by
#      docs/multi-cloud-parity/oci/identity-model.md and has not landed).
#      So this fetch WILL fail until that lands. It fails SOFT, on purpose:
#      the baked-in default /etc/squid/squid.conf stays in place and Squid
#      still starts. That default denies everything not on the allowlist and
#      the baked-in allowlist is empty, so the failure mode is "no outbound
#      traffic is permitted", not "everything is permitted". An egress proxy
#      that cannot read its config must fail closed.
# =============================================================================

IMDS="http://169.254.169.254/opc/v2/instance/metadata"
HDR="Authorization: Bearer Oracle"

# The /opc/v2/ path is token-gated: without the Bearer header OCI returns 401.
# That is the IMDSv2-equivalent the composition module's
# `are_legacy_imds_endpoints_disabled` relies on - once legacy /opc/v1/ is
# disabled this header is the ONLY way to read metadata at all.
# -f so a missing key is an error (empty result) rather than an HTML body
# assigned to a variable; the same trap GCP's version documents.
md() { curl -sf -H "${HDR}" "${IMDS}/$1" 2>/dev/null | tr -d '"' || true; }

CONFIG_BUCKET=$(md config_bucket)
CONFIG_NAMESPACE=$(md config_namespace)
CONFIG_OBJECT=$(md squid_config_object)
CONFIG_OBJECT="${CONFIG_OBJECT:-squid.conf}"

if [ -z "${CONFIG_BUCKET}" ] || [ -z "${CONFIG_NAMESPACE}" ]; then
  echo "fetch-squid-config: no config_bucket/config_namespace metadata set, leaving baked-in /etc/squid/squid.conf in place" >&2
  exit 0
fi

TMP_FILE=$(mktemp)
trap 'rm -f "${TMP_FILE}" /etc/squid/squid.conf.candidate' EXIT

if ! oci os object get \
      --auth instance_principal \
      --namespace "${CONFIG_NAMESPACE}" \
      --bucket-name "${CONFIG_BUCKET}" \
      --name "${CONFIG_OBJECT}" \
      --file "${TMP_FILE}" >/dev/null 2>&1; then
  echo "fetch-squid-config: could not fetch os://${CONFIG_NAMESPACE}/${CONFIG_BUCKET}/${CONFIG_OBJECT} (no instance principal yet?), leaving baked-in config in place" >&2
  exit 0
fi

# Validate BEFORE installing. Neither the AWS nor the GCP version does this,
# and both are worse for it: a syntactically broken squid.conf pushed to the
# bucket takes the whole egress path down on the next boot with no way to roll
# back from inside the instance. `squid -k parse -f` is a pure syntax check and
# costs milliseconds.
install -o root -g root -m 0644 "${TMP_FILE}" /etc/squid/squid.conf.candidate
if ! squid -k parse -f /etc/squid/squid.conf.candidate >/dev/null 2>&1; then
  echo "fetch-squid-config: fetched config FAILED squid -k parse, refusing to install it; keeping the previous /etc/squid/squid.conf" >&2
  exit 0
fi

cp -a /etc/squid/squid.conf /etc/squid/squid.conf.old 2>/dev/null || true
install -o root -g root -m 0644 /etc/squid/squid.conf.candidate /etc/squid/squid.conf
echo "fetch-squid-config: installed ${CONFIG_OBJECT} from ${CONFIG_BUCKET}"

# WHY --no-block, VERBATIM FROM THE GCP SCRIPT - this was learned from two
# separate live systemd hangs and the reasoning is identical on OCI:
#
# squid.service isn't running yet on the normal boot-time invocation of this
# script - squid-config-fetch.service has Before=squid.service, so squid.service
# starts fresh right after this script exits and reads the config just written
# above on its own; no restart needed there.
#
# A plain `systemctl restart squid.service` here is unsafe in ANY invocation of
# this script, not just at boot: this unit carries Before=squid.service, and
# that ordering constraint is enforced against whatever job this script's own
# `systemctl restart` call schedules for squid.service too - a BLOCKING restart
# call deadlocks systemd (this unit's start job can't finish until the restart
# job completes, but the restart job is itself held behind this unit's own
# Before= ordering). An is-active guard alone does not avoid this; only
# --no-block does.
if systemctl is-active --quiet squid.service; then
  systemctl restart --no-block squid.service
fi
