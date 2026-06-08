#!/bin/bash
set -e

# Variables from template
ENVIRONMENT="${environment}"
CLOUDWATCH_REGION="${cloudwatch_region}"

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

# Create custom MOTD in a way it won't be overwritten by cloud-init or other services
cat > /etc/motd.d/40-hyperswitch <<EOF
================================================================================
  Jump Host - $ENVIRONMENT Environment

  Access: AWS Systems Manager Session Manager
  No SSH keys required - access via AWS Console or AWS CLI

  Managed by Terraform
================================================================================
EOF

update-motd

echo "Jump host setup complete in $ENVIRONMENT"
