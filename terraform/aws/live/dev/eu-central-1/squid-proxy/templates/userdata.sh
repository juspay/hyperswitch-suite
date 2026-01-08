#!/bin/bash

set -e
LOG_FILE="/var/log/squid-userdata.log"
exec > >(tee -a "$LOG_FILE") 2>&1

BUCKET_NAME="{{bucket-name}}"
BUCKET_PATH_PREFIX="{{bucket-path-prefix}}"

echo "$(date '+%H:%M:%S') Starting Squid userdata script"

# Setup Wazuh Agent Configuration (optional - skip if fails)
echo "$(date '+%H:%M:%S') Setting up Wazuh configuration"
echo "$(date '+%H:%M:%S') Downloading wazuh.conf to /var/ossec/etc/ossec.conf"
sudo aws s3 cp "s3://${BUCKET_NAME}/${BUCKET_PATH_PREFIX}/wazuh.conf" "/var/ossec/etc/ossec.conf" || echo "Wazuh config not found, skipping..."
if [ -f "/var/ossec/etc/ossec.conf" ]; then
    sudo chown root:wazuh /var/ossec/etc/ossec.conf
    sudo chmod 640 /var/ossec/etc/ossec.conf
fi

# Setup Vector Configuration (optional - skip if fails)
echo "$(date '+%H:%M:%S') Setting up Vector configuration"
echo "$(date '+%H:%M:%S') Downloading squid_vector.toml to /etc/vector/vector.toml"
sudo aws s3 cp "s3://${BUCKET_NAME}/${BUCKET_PATH_PREFIX}/squid_vector.toml" "/etc/vector/vector.toml" || echo "Vector config not found, skipping..."
if [ -f "/etc/vector/vector.toml" ]; then
    sudo chown vector:vector /etc/vector/vector.toml 2>/dev/null || true
    sudo chmod 644 /etc/vector/vector.toml
    sudo usermod -a -G squid vector 2>/dev/null || true
    sudo rm -f /etc/vector/vector.yaml
    sudo systemctl restart vector 2>/dev/null || true
fi

# Setup Squid Configuration
echo "$(date '+%H:%M:%S') Setting up Squid configuration"
echo "$(date '+%H:%M:%S') Downloading squid.conf to /etc/squid/squid.conf"
sudo aws s3 cp "s3://${BUCKET_NAME}/${BUCKET_PATH_PREFIX}/squid.conf" "/etc/squid/squid.conf"
sudo chown root:squid /etc/squid/squid.conf
sudo chmod 644 /etc/squid/squid.conf

# Setup whitelist update mechanism
echo "$(date '+%H:%M:%S') Setting up whitelist updates"
sudo mkdir -p /var/spool/squid
sudo chown squid:squid /var/spool/squid

# Create whitelist update script
sudo cat > /etc/squid/update_whitelist.sh << 'EOF'
#!/bin/bash
sudo aws s3 cp "s3://{{bucket-name}}/squid/whitelist.txt" "/tmp/whitelist.txt"
if [ $? -eq 0 ]; then
    if [ -f "/etc/squid/squid.allowed.sites.txt" ]; then
        upstreamVersion=$(md5sum /tmp/whitelist.txt | awk '{print $1}')
        hostVersion=$(md5sum /etc/squid/squid.allowed.sites.txt | awk '{print $1}')
    else
        hostVersion=""
    fi

    if [ "$upstreamVersion" != "$hostVersion" ]; then
        sudo cp /tmp/whitelist.txt /etc/squid/squid.allowed.sites.txt
        sudo chown squid:squid /etc/squid/squid.allowed.sites.txt
        sudo chmod 644 /etc/squid/squid.allowed.sites.txt
        /usr/sbin/squid -k reconfigure
    fi
    rm -f /tmp/whitelist.txt
fi
EOF
sudo sed -i "s/{{bucket-name}}/$BUCKET_NAME/g" /etc/squid/update_whitelist.sh
sudo chmod +x /etc/squid/update_whitelist.sh

# Run initial update
sudo bash /etc/squid/update_whitelist.sh

# Add cron job (only if not already present)
if ! grep -q "update_whitelist.sh" /etc/crontab; then
    echo "*/15 * * * * root /etc/squid/update_whitelist.sh" | sudo tee -a /etc/crontab
fi

# Restart squid (squid is pre-installed on the AMI)
sudo systemctl restart squid
sudo systemctl enable squid

echo "$(date '+%H:%M:%S') Squid userdata script completed"
