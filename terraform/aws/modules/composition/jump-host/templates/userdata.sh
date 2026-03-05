#!/bin/bash
set -e

# Variables from template
JUMP_TYPE="${jump_type}"
ENVIRONMENT="${environment}"
CLOUDWATCH_REGION="${cloudwatch_region}"
OS_USERNAME="${os_username}"
%{ if jump_type == "external" ~}
INTERNAL_JUMP_IP="${internal_jump_ip}"
%{ endif ~}

# Security hardening - SSH configuration
cat >> /etc/ssh/sshd_config <<EOF

# Security hardening
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 60
EOF

# Restart SSH service
systemctl restart sshd

# Type-specific configuration
if [ "$JUMP_TYPE" = "external" ]; then
  # Check to see whether SSM access username exists, creating it and its similarly named group, and home directory if not.
  if ! id -u $OS_USERNAME >/dev/null 2>&1; then
    useradd --create-home --user-group --shell /bin/bash $OS_USERNAME

    # Create sudoers file to allow SSM access username to execute commands as root without password, same as SSM Agent would have.
    cat > /etc/sudoers.d/ssm-agent-users <<SUDOEOF
# User rules for $OS_USERNAME
$OS_USERNAME ALL=(ALL) NOPASSWD:ALL
SUDOEOF
  fi

  # External jump - retrieve internal jump SSH key from SSM
  # This works because external jump has IAM permissions to read from SSM
  INTERNAL_SSH_KEY_OUTPUT=$(aws ssm get-parameter \
    --name "/jump-host/$ENVIRONMENT/internal/ssh-private-key" \
    --with-decryption \
    --region $CLOUDWATCH_REGION \
    --query 'Parameter.Value' \
    --output text 2>&1)
  INTERNAL_SSH_KEY_EXIT_CODE=$?
  if [ $INTERNAL_SSH_KEY_EXIT_CODE -ne 0 ] || [ -z "$INTERNAL_SSH_KEY_OUTPUT" ]; then
    echo "[ERROR] Failed to retrieve internal jump SSH key from SSM for environment '$ENVIRONMENT' in region '$CLOUDWATCH_REGION'." >&2
    echo "[ERROR] AWS CLI output: $INTERNAL_SSH_KEY_OUTPUT" >&2
    exit 1
  fi
  INTERNAL_SSH_KEY="$INTERNAL_SSH_KEY_OUTPUT"

  # Store SSH key for OS user
  mkdir -p /home/$OS_USERNAME/.ssh
  chmod 700 /home/$OS_USERNAME/.ssh
  echo "$INTERNAL_SSH_KEY" > /home/$OS_USERNAME/.ssh/internal_jump_key
  chmod 600 /home/$OS_USERNAME/.ssh/internal_jump_key

  # Create SSH config for easy connection
  cat > /home/$OS_USERNAME/.ssh/config <<SSHEOF
Host internal-jump
    HostName $INTERNAL_JUMP_IP
    User ec2-user
    IdentityFile ~/.ssh/internal_jump_key
    StrictHostKeyChecking no
SSHEOF
  chmod 600 /home/$OS_USERNAME/.ssh/config

  # Finally, recursively set ownership of the entire home directory
  chown -R $OS_USERNAME:$OS_USERNAME /home/$OS_USERNAME

  echo "External jump configured. Internal jump: $INTERNAL_JUMP_IP"
fi

# Create custom MOTD in a way it won't be overwritten by cloud-init or other services and is shown at the end of the default MOTD content.
# Note that motd doesn't get shown when logging in via SSM Session Manager, but it will if logging in via SSH
cat > /etc/motd.d/40-hyperswitch <<EOF
================================================================================
  $JUMP_TYPE Jump Host - $ENVIRONMENT Environment

  Default User: $OS_USERNAME
  Access: AWS Systems Manager Session Manager
$([ "$JUMP_TYPE" = "external" ] && echo "  SSH to Internal: ssh internal-jump")

  Managed by Terraform
================================================================================
EOF

update-motd

echo "Jump host setup complete for $JUMP_TYPE in $ENVIRONMENT"
