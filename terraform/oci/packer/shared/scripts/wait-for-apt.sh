#!/bin/bash
set -euo pipefail

# =============================================================================
# Wait until nothing else is holding apt/dpkg locks.
# =============================================================================
# WHY THIS EXISTS, AND WHY GCP's ONE-LINER IS NOT ENOUGH ON OCI.
#
# The GCP squid template guards its first `apt-get update` with
# `sudo cloud-init status --wait` and a comment recording a real, twice
# reproduced failure it fixed ("E: Unable to correct problems, you have held
# broken packages"). That guard is necessary on OCI too - and it is NOT
# sufficient. Reproduced on the first real OCI build, 2026-09-05:
#
#     + sudo cloud-init status --wait
#     ....status: done
#     + sudo apt-get update -qq
#     E: Could not get lock /var/lib/apt/lists/lock. It is held by process 1953 (apt)
#     E: Unable to lock directory /var/lib/apt/lists/
#
# cloud-init genuinely HAD finished. The lock holder was something else:
# Canonical's OCI images enable the `apt-daily.timer` /
# `apt-daily-upgrade.timer` / `unattended-upgrades.service` set, and those fire
# on their own schedule shortly after boot, independent of cloud-init. On GCE's
# Ubuntu images the same timers exist but cloud-init's first-boot work overlaps
# them differently, so the GCP build never observed this. The distinction
# matters: "wait for cloud-init" and "wait for apt to be free" are two
# different questions, and only the GCP template's answer to the first one was
# portable.
#
# Two mechanisms, deliberately both:
#
#   1. `systemd-run --wait` with After= ordering against the three apt units.
#      This is the deterministic one: systemd will not start the transient unit
#      until those jobs have finished, so it BLOCKS rather than polls. It is a
#      no-op (returns immediately) if none of them is running.
#
#   2. A bounded poll on the actual lock files. This catches a manually
#      launched apt, an apt started by something outside those three units, and
#      the race where a timer fires in the gap between (1) returning and
#      apt-get starting.
#
# Neither is a `sleep 60`. A fixed sleep is both slower on a quiet machine and
# still wrong on a busy one.
# =============================================================================

echo "wait-for-apt: waiting for cloud-init"
cloud-init status --wait || true

echo "wait-for-apt: waiting for apt-daily / unattended-upgrades units"
systemd-run \
  --property="After=apt-daily.service apt-daily-upgrade.service unattended-upgrades.service" \
  --wait /bin/true >/dev/null 2>&1 || true

echo "wait-for-apt: polling apt/dpkg locks"
LOCKS="/var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock"
for _ in $(seq 1 120); do
  HELD=0
  for lock in ${LOCKS}; do
    [ -e "${lock}" ] || continue
    if fuser "${lock}" >/dev/null 2>&1; then
      HELD=1
      break
    fi
  done
  [ "${HELD}" = "0" ] && { echo "wait-for-apt: locks free"; exit 0; }
  sleep 5
done

# Ten minutes is well past any plausible unattended-upgrades run. Report what
# is actually holding the lock rather than failing with the same opaque
# "Could not get lock" apt-get would print.
echo "wait-for-apt: apt locks still held after 600s:" >&2
for lock in ${LOCKS}; do
  [ -e "${lock}" ] || continue
  fuser -v "${lock}" >&2 2>&1 || true
done
exit 1
