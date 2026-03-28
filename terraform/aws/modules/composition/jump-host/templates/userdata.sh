#!/bin/bash
set -e

# Variables from template
ENVIRONMENT="${environment}"
CLOUDWATCH_REGION="${cloudwatch_region}"
OS_USERNAME="${os_username}"

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

# Create SSM access user
if ! id -u $OS_USERNAME >/dev/null 2>&1; then
  useradd --create-home --user-group --shell /bin/bash $OS_USERNAME

  # Create sudoers file to allow SSM access username to execute commands as root without password
  cat > /etc/sudoers.d/ssm-agent-users <<SUDOEOF
# User rules for $OS_USERNAME
$OS_USERNAME ALL=(ALL) NOPASSWD:ALL
SUDOEOF
fi

# Set up .ssh directory
mkdir -p /home/$OS_USERNAME/.ssh
chmod 700 /home/$OS_USERNAME/.ssh
chown -R $OS_USERNAME:$OS_USERNAME /home/$OS_USERNAME

# Create custom MOTD
cat > /etc/motd.d/40-hyperswitch <<EOF
================================================================================
  Jump Host - $ENVIRONMENT Environment

  Default User: $OS_USERNAME
  Access: AWS Systems Manager Session Manager

  Managed by Terraform
================================================================================
EOF

update-motd

echo "Jump host setup complete for $ENVIRONMENT"
