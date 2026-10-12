#!/bin/bash
# =============================================================================
# Jump-host hardening - belt and braces
# =============================================================================
# Content ported from the AWS module's templates/userdata.sh with NO logic
# changes. Only the delivery mechanism differs: this arrives base64-encoded via
# oci_core_instance.metadata.user_data and is read by cloud-init from
# http://169.254.169.254/opc/v2/instance/metadata/, where on AWS it arrived
# through a launch template. cloud-init is cloud-init.
#
# One thing that DID change in meaning: on AWS this is belt-and-braces, because
# SSM Session Manager is the primary path and needs no sshd at all. Here sshd
# is the ONLY path - OCI Bastion's PORT_FORWARDING session forwards to this
# host's own sshd. So disabling password auth and root login is not a secondary
# hardening measure any more; it is the entire authentication posture.

set -euo pipefail

hostnamectl set-hostname "${hostname}" || true

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

# Validate before restarting: a syntax error here locks the only way in.
sshd -t

systemctl restart sshd || systemctl restart ssh
