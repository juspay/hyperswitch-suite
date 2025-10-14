#!/bin/bash

set -e
LOG_FILE="/var/log/squid-userdata.log"
exec > >(tee -a "$LOG_FILE") 2>&1

BUCKET_NAME="{{bucket-name}}"
S3_PREFIX="squid"
SQUID_LOGS_BUCKET="{{squid-logs-bucket}}"

echo "$(date '+%H:%M:%S') Starting Squid userdata script"
# Setup Wazuh Agent Configuration
echo "$(date '+%H:%M:%S') Setting up Wazuh configuration"
echo "$(date '+%H:%M:%S') Downloading wazuh.conf to /var/ossec/etc/ossec.conf"
sudo aws s3 cp "s3://${BUCKET_NAME}/${S3_PREFIX}/wazuh.conf" "/var/ossec/etc/ossec.conf"
sudo chown root:wazuh /var/ossec/etc/ossec.conf
sudo chmod 640 /var/ossec/etc/ossec.conf

# Setup Vector Configuration
echo "$(date '+%H:%M:%S') Setting up Vector configuration"
echo "$(date '+%H:%M:%S') Downloading squid_vector.toml to /etc/vector/vector.toml"
sudo aws s3 cp "s3://${BUCKET_NAME}/${S3_PREFIX}/squid_vector.toml" "/etc/vector/vector.toml"
sudo sed -i "s|{{squid_logs_bucket}}|$SQUID_LOGS_BUCKET|g" /etc/vector/vector.toml
sudo chown vector:vector /etc/vector/vector.toml
sudo chmod 644 /etc/vector/vector.toml
sudo usermod -a -G squid vector
sudo rm -f /etc/vector/vector.yaml
sudo systemctl restart vector

# Setup Squid Configuration
echo "$(date '+%H:%M:%S') Setting up Squid configuration"
echo "$(date '+%H:%M:%S') Downloading squid.conf to /etc/squid/squid.conf"
sudo aws s3 cp "s3://${BUCKET_NAME}/${S3_PREFIX}/squid.conf" "/etc/squid/squid.conf"
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

# Add cron job
echo "*/15 * * * * root /etc/squid/update_whitelist.sh" | sudo tee -a /etc/crontab

# start squid
sudo systemctl restart squid
sudo systemctl enable squid

echo "$(date '+%H:%M:%S') Squid userdata script completed"