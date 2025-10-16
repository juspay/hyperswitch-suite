#!/bin/bash
# Custom Squid Userdata Script for Hyperswitch
# This script will be executed when the instance launches

set -e

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/squid-init.log
}

log "Starting Squid proxy initialization..."

# Update system packages
log "Updating system packages..."
yum update -y || apt-get update -y

# Install required packages
log "Installing required packages..."
if command -v yum &> /dev/null; then
    yum install -y squid aws-cli amazon-cloudwatch-agent
else
    apt-get install -y squid awscli amazon-cloudwatch-agent
fi

# Create squid cache directory
log "Creating Squid cache directory..."
mkdir -p /var/spool/squid
chown -R squid:squid /var/spool/squid

# Initialize Squid cache
log "Initializing Squid cache..."
squid -z

# Enable and start Squid service
log "Enabling and starting Squid service..."
systemctl enable squid
systemctl start squid

log "Squid proxy initialization completed successfully!"
log "Squid is running on port 3128"
