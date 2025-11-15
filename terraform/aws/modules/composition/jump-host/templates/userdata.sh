#!/bin/bash
set -e

# Variables from template
JUMP_TYPE="${jump_type}"
ENVIRONMENT="${environment}"
CLOUDWATCH_REGION="${cloudwatch_region}"
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

  # Store SSH key for ec2-user
  mkdir -p /home/ec2-user/.ssh
  echo "$INTERNAL_SSH_KEY" > /home/ec2-user/.ssh/internal_jump_key
  chmod 600 /home/ec2-user/.ssh/internal_jump_key
  chown ec2-user:ec2-user /home/ec2-user/.ssh/internal_jump_key

  # Create SSH config for easy connection
  cat > /home/ec2-user/.ssh/config <<SSHEOF
Host internal-jump
    HostName $INTERNAL_JUMP_IP
    User ec2-user
    IdentityFile ~/.ssh/internal_jump_key
    StrictHostKeyChecking no
SSHEOF
  chmod 600 /home/ec2-user/.ssh/config
  chown ec2-user:ec2-user /home/ec2-user/.ssh/config

  echo "External jump configured. Internal jump: $INTERNAL_JUMP_IP"
fi

# Create MOTD
cat > /etc/motd <<EOF
================================================================================
  $JUMP_TYPE Jump Host - $ENVIRONMENT Environment

  Default User: ec2-user
  Access: AWS Systems Manager Session Manager
$([ "$JUMP_TYPE" = "external" ] && echo "  SSH to Internal: ssh internal-jump")

  Managed by Terraform
================================================================================
EOF

echo "Jump host setup complete for $JUMP_TYPE in $ENVIRONMENT"
