#!/bin/bash
# =============================================================================
# Security-team audit instance - boot-time hardening (secreview-style)
# =============================================================================
# Creates a dedicated NON-ROOT user with sudo, authorizes the security team's
# SSH key for it, hardens sshd to key-only, denies root login, and configures
# ufw to allow tcp:22 from exactly the corporate VPN/office source ranges.
# Mirrors the GCP `secreview` review-VM pattern. NO real key is baked here -
# it arrives as var.ssh_public_key at apply time.
#
# Values are interpolated by Terraform's templatefile() before cloud-init runs.
# `$$` escapes are used where a literal shell `$` is required.

set -euo pipefail

hostnamectl set-hostname "${hostname}" || true

# ---- 1. Create the dedicated non-root review user with passwordless sudo ----
if ! id "${review_user}" &>/dev/null; then
  useradd --create-home --shell /bin/bash --groups sudo "${review_user}"
fi

mkdir -p /home/"${review_user}"/.ssh
printf '%s\n' "${ssh_public_key}" > /home/"${review_user}"/.ssh/authorized_keys
chmod 700 /home/"${review_user}"/.ssh
chmod 600 /home/"${review_user}"/.ssh/authorized_keys
chown -R "${review_user}":"${review_user}" /home/"${review_user}"/.ssh

# ---- 2. Harden sshd: key-only, no root login, no password ----
SSHD_CONFIG=/etc/ssh/sshd_config

harden() {
  local key="$1" value="$2"
  if grep -qE "^[[:space:]]*#?[[:space:]]*$${key}[[:space:]]" "$SSHD_CONFIG"; then
    sed -i -E "s|^[[:space:]]*#?[[:space:]]*$${key}[[:space:]].*|$${key} $${value}|" "$SSHD_CONFIG"
  else
    printf '%s %s\n' "$${key}" "$${value}" >> "$SSHD_CONFIG"
  fi
}

harden PasswordAuthentication no
harden PermitRootLogin no
harden ChallengeResponseAuthentication no
harden PermitEmptyPasswords no
harden PubkeyAuthentication yes

sshd -t  # validate before restarting; a syntax error here locks the only way in
systemctl restart sshd || systemctl restart ssh || true

# ---- 3. ufw: allow tcp:22 from the VPN/office ranges ONLY. ----
ufw --force reset >/dev/null 2>&1 || true

# shellcheck disable=SC2086
for cidr in ${vpn_source_cidrs}; do
  ufw allow from "$${cidr}" to any port 22 proto tcp
done

ufw default deny incoming
ufw default allow outgoing
ufw --force enable >/dev/null
ufw reload >/dev/null || true