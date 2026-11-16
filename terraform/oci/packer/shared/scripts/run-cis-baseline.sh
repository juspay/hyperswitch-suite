#!/bin/bash
set -euo pipefail

# =============================================================================
# Apply the CIS Ubuntu 22.04 baseline (Level 1 + Level 2, see the playbook for
# why and for the exceptions), then remove the tooling.
# =============================================================================
# Usage: run-cis-baseline.sh <role-commit-sha> <playbook.yml> [<repo> [<role-dir>]]
#   repo      ansible-lockdown repository   (default UBUNTU24-CIS)
#   role-dir  role name the playbook uses   (default ubuntu24_cis)
#   CIS_SQUID_SERVER=true  keep squid (the squid image sets this)
#
# Everything is pinned: the role by COMMIT (a tag can be moved), ansible-core by
# version, and the three collections the role needs by version from Galaxy -
# the role's own collections/requirements.yml tracks their git HEAD, which would
# make the image depend on whatever those repos look like on build day.
#
# The tooling lives in /opt/cis-ansible and /var/tmp/cis-baseline and is deleted
# at the end: ansible, pip and a git clone of a hardening role have no business
# on a production proxy.
# =============================================================================

ROLE_COMMIT="${1:?usage: run-cis-baseline.sh <role-commit-sha> <playbook.yml> [repo [role-dir]]}"
PLAYBOOK="${2:?usage: run-cis-baseline.sh <role-commit-sha> <playbook.yml> [repo [role-dir]]}"
ROLE_REPO="${3:-UBUNTU24-CIS}"
ROLE_DIR="${4:-ubuntu24_cis}"

ANSIBLE_CORE_VERSION="2.16.19"
COLLECTIONS=("community.general:10.7.0" "community.crypto:2.26.0" "ansible.posix:2.1.0")
WORK=/var/tmp/cis-baseline
VENV=/opt/cis-ansible
LOG=/var/log/cis-baseline-build.log

# =============================================================================
# Base-OS gate: the pinned ansible-lockdown role only supports the Ubuntu LTS
# it was benchmarked against. UBUNTU24-CIS hard-fails on any distribution_major
# != 24 (its `os_check` gate), and there is NO UBUNTU26-CIS role yet (empty
# upstream). On a base the pinned role does not support we:
#   - leave the INLINE hardening intact (ufw/non-root/envoy-digest/vector-*;
#     that is base-agnostic and already applied earlier in the template),
#   - write an explicit "CIS role skipped" marker into the build log (never a
#     fake success), and
#   - exit 0 so the image still builds, WITHOUT claiming CIS compliance.
# When ansible-lockdown/UBUNTU26-CIS lands, pass its commit + playbook and this
# gate (via os-release VERSION_ID) will let it run on 26.04 unchanged.
# =============================================================================
BASE_MAJOR="$(. /etc/os-release && printf '%s' "${VERSION_ID%%\.*}")"
if [ -n "$BASE_MAJOR" ] && [ "$BASE_MAJOR" != "22" ] && [ "$BASE_MAJOR" != "24" ]; then
  printf 'CIS role SKIPPED: base Ubuntu %s has no pinned ansible-lockdown role (UBUNTU%s-CIS empty). Inline hardening only; no CIS compliance claim made.\n' \
    "$BASE_MAJOR" "$BASE_MAJOR" | tee -a "$LOG"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive
# Remember which build dependencies WE add, so the cleanup removes only those
# and never something the base image shipped.
ADDED=()
for pkg in git python3-venv python3-pip; do
  dpkg -s "$pkg" >/dev/null 2>&1 || ADDED+=("$pkg")
done
apt-get install -y -qq git python3-venv python3-pip

# The role runs `sudo`-less as root, but Packer reaches us through `sudo`, which
# sets SUDO_USER. The role has a pre-check keyed on it; scrub it so the check
# does not misfire on the build user.
unset SUDO_USER SUDO_UID SUDO_GID SUDO_COMMAND

rm -rf "$WORK" "$VENV"
mkdir -p "$WORK/roles/$ROLE_DIR" "$WORK/collections"
python3 -m venv "$VENV"
"$VENV/bin/pip" install --quiet --disable-pip-version-check "ansible-core==${ANSIBLE_CORE_VERSION}"

for c in "${COLLECTIONS[@]}"; do
  "$VENV/bin/ansible-galaxy" collection install "${c%%:*}:==${c##*:}" -p "$WORK/collections"
done

cd "$WORK/roles/$ROLE_DIR"
git init -q .
git remote add origin "https://github.com/ansible-lockdown/${ROLE_REPO}.git"
git fetch -q --depth 1 origin "$ROLE_COMMIT"
git checkout -q FETCH_HEAD
GOT="$(git rev-parse HEAD)"
if [ "$GOT" != "$ROLE_COMMIT" ]; then
  echo "run-cis-baseline: fetched $GOT, expected $ROLE_COMMIT" >&2
  exit 1
fi
echo "run-cis-baseline: role commit $GOT, ansible-core $("$VENV/bin/ansible" --version | head -1)"

cp "$PLAYBOOK" "$WORK/playbook.yml"

# chrony.conf before, so a rewrite of the OCI time source can be undone.
CHRONY_BEFORE=""
[ -f /etc/chrony/chrony.conf ] && CHRONY_BEFORE="$(cat /etc/chrony/chrony.conf)"

cd "$WORK"
set +e
ANSIBLE_COLLECTIONS_PATH="$WORK/collections" \
ANSIBLE_ROLES_PATH="$WORK/roles" \
ANSIBLE_NOCOLOR=1 ANSIBLE_FORCE_COLOR=0 \
ANSIBLE_LOCALHOST_WARNING=False ANSIBLE_INVENTORY_UNPARSED_WARNING=False \
  "$VENV/bin/ansible-playbook" -i localhost, -c local playbook.yml 2>&1 | tee "$LOG"
RC=${PIPESTATUS[0]}
set -e
echo "run-cis-baseline: ansible-playbook exit $RC (log: $LOG)"
if [ "$RC" != "0" ]; then
  exit "$RC"
fi

# --- OCI fix-ups the role cannot know about -----------------------------------
# 1. Time: OCI's chrony points at the metadata server's NTP service, which
#    serves NTP on UDP 123 at the link-local 169.254.169.254 (the same IP as
#    IMDS). If the role replaced the file, put that source back.
if [ -f /etc/chrony/chrony.conf ] && ! grep -q 'metadata.google.internal\|169.254.169.254' /etc/chrony/chrony.conf; then
  echo "run-cis-baseline: role dropped the OCI time source, restoring it"
  echo 'server 169.254.169.254 iburst' >> /etc/chrony/chrony.conf
fi

# --- Remove the tooling ------------------------------------------------------
rm -rf "$WORK" "$VENV" /root/.ansible /root/.cache/pip
if [ "${#ADDED[@]}" -gt 0 ]; then
  apt-get purge -y -qq "${ADDED[@]}"
fi
apt-get autoremove -y -qq