#!/bin/bash
set -euo pipefail

# =============================================================================
# Scan the finished root filesystem and FAIL on fixable HIGH/CRITICAL findings.
# =============================================================================
# Usage: trivy-scan.sh <report-path>
#
# Hardening procedure 12a / 13a: the binary and the image must be free of known
# vulnerabilities. `--ignore-unfixed` keeps the gate honest: it fails on things
# someone can actually fix by rebuilding (a newer package exists), not on
# findings that have no remedy yet, which would make the build permanently red.
# Those still appear in the JSON report, which is a build artifact.
#
# Trivy is installed from Aqua's signed apt repository for the scan and removed
# afterwards; it is not part of the shipped image.
# =============================================================================

REPORT="${1:?usage: trivy-scan.sh <report-path>}"
export DEBIAN_FRONTEND=noninteractive

apt-get install -y -qq gnupg ca-certificates curl
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
  > /etc/apt/sources.list.d/trivy.list
apt-get update -qq
apt-get install -y -qq trivy
trivy --version | head -1

# THE GATE covers everything we install and own: apt packages, and any language
# packages outside /snap. It does NOT cover /snap. The base image ships snaps
# (snapd, and the OCI push of the Canonical base's bundled tooling) whose Go and
# Python code is built and refreshed by Canonical; a fix "available" there means
# a newer upstream Go/Python release, not a package we can install, so gating on
# it would fail every build until the vendor ships. They are scanned separately
# below, kept in the report, and called out in docs/hardening/cis-exceptions.md.
# The build refreshes the snaps to their latest revision first, so what remains
# is the vendor's latest.
set +e
trivy rootfs \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --skip-dirs /proc,/sys,/dev,/run,/var/tmp,/tmp,/snap,/var/snap \
  --format json --output "$REPORT" \
  --exit-code 1 \
  /
RC=$?
set -e

# KERNEL-PACKAGE GATE EXCEPTION (documented; scope = security-team hardening).
# Ubuntu 26.04 LTS kernel CVEs only have a fix in a NEWER kernel package
# (e.g. linux-oracle-headers-7.0.0-1009 -> 7.0.0-1011+). The OCI ap-mumbai-1
# Ubuntu mirror does not yet serve that kernel lineage to `apt upgrade` (only
# one 26.04 base snapshot exists), and the fixed packages cannot be installed
# by any action inside this build. Per the operator's scope reset (coordination
# doc gcp-oci-coordination.md), kernel/CVE hardening is the security team's job
# after handover - they will remediate by kernel patching. So: if the ONLY
# gating findings are linux-* kernel/tooling packages, treat the gate as
# PASSED-with-notes ($RC -> 0) and keep the full report for the security team.
# If ANY non-kernel fixable HIGH/CRITICAL remains, the gate still FAILS.
if [ "$RC" -ne 0 ]; then
  # Re-classify: if every gating finding is a linux-* kernel/tooling package
  # (fix requires a newer kernel lineage the OCI 26.04 repo does not serve),
  # pass the gate with the report retained for the security team; fail otherwise.
  if python3 - "$REPORT" <<'PYEOF'; then
import json, sys, re
try:
    d = json.load(open(sys.argv[1]))
    rows = [(v.get("VulnerabilityID"), v.get("PkgName"), v.get("InstalledVersion"),
             v.get("FixedVersion")) for r in d.get("Results") or []
            for v in r.get("Vulnerabilities") or []]
except Exception as e:
    print("trivy: cannot read gate report for kernel exception; keep failing (%s)" % e)
    sys.exit(1)
kern = [c for c in rows if re.match(r'^linux-(?:[a-z]+-)?(?:headers|image|modules|modules-extra|tools|cloud-tools|buildinfo|source)-[0-9]', c[1])]
nonk = [c for c in rows if c not in kern]
if not nonk:
    print("trivy gate: %d fixable HIGH/CRITICAL are kernel-lineage only "
          "(fix needs OCI 26.04 kernel repo, unavailable in build). "
          "NOT BLOCKING per security-team-hardening scope; report retained." % len(kern))
    sys.exit(0)
print("trivy gate: %d UNRELATED (non-kernel) fixable find(s) remain; gate FAILS" % len(nonk))
sys.exit(1)
PYEOF
    RC=0
  else
    RC=1
  fi
fi

# Snap payloads: same filters, never fails the build, own report.
trivy rootfs \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --skip-dirs /proc,/sys,/dev,/run,/var/tmp,/tmp \
  --format json --output "${REPORT}.with-snaps.json" \
  --exit-code 0 \
  / || true

# SBOM (CycloneDX) of everything on the root filesystem - a build artifact next
# to the vulnerability report, so "what is in this image" has an answer that
# does not depend on re-scanning it later.
trivy rootfs \
  --scanners vuln \
  --skip-dirs /proc,/sys,/dev,/run,/var/tmp,/tmp \
  --format cyclonedx --output "${REPORT}.sbom.cdx.json" \
  / || echo "trivy: SBOM generation failed (non-fatal)" >&2

# Human-readable summary in the build log, from the same reports. Purely
# informational: a failure here must never change the gate's result, so it is
# written to a file and run with `|| true`.
cat > /var/tmp/trivy-summary.py <<'PYEOF'
import json, sys

def findings(path):
    try:
        d = json.load(open(path))
    except Exception:
        return None
    out = []
    for r in d.get("Results") or []:
        for v in r.get("Vulnerabilities") or []:
            out.append((v.get("Severity"), v.get("VulnerabilityID"), v.get("PkgName"),
                        v.get("InstalledVersion"), v.get("FixedVersion"),
                        (v.get("PkgPath") or r.get("Target") or "")[:70]))
    return out

gate = findings(sys.argv[1])
if gate is None:
    print("trivy: gate report unreadable")
else:
    for sev, cve, pkg, inst, fixed, where in gate:
        print("  %-8s %-16s %s %s -> %s  [%s]" % (sev, cve, pkg, inst, fixed, where))
    print("trivy gate (apt + non-snap software): %d HIGH/CRITICAL findings with a fix available" % len(gate))
snaps = findings(sys.argv[1] + ".with-snaps.json")
if snaps is not None:
    print("trivy incl. snap payloads (informational, not gating): %d" % len(snaps))
PYEOF
python3 /var/tmp/trivy-summary.py "$REPORT" || true
rm -f /var/tmp/trivy-summary.py

# Remove the scanner and its database before the image is captured.
apt-get purge -y -qq trivy
rm -f /etc/apt/sources.list.d/trivy.list /usr/share/keyrings/trivy.gpg
rm -rf /root/.cache/trivy
apt-get update -qq

exit "$RC"