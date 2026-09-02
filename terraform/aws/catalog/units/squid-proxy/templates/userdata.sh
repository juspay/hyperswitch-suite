#!/bin/bash

# ------------------------------ Variables ------------------------------ #
BUCKET_NAME="{{bucket-name}}"
BUCKET_PATH_PREFIX="{{bucket-path-prefix}}"
LOGS_BUCKET="{{logs_bucket}}"

# Fetch EC2 region using IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300" -s)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)

###### Creating Mappings Script ######
cat <<EOT > /home/ubuntu/mapping.sh
#!/bin/bash
export UPDATE_CLAMAV_DNS="Disable"
export CLAMAV_DNS="NA"
export UPDATE_SURICATA_DNS="Disable"
export SURICATA_DNS="NA"
export UPDATE_WAZUH="{{update-wazuh}}"
export WAZUH_MANAGER_ADDR="{{wazuh-manager-addr}}"
export WAZUH_WORKER_ADDR="{{wazuh-worker-addr}}"
export WAZUH_GROUP="{{wazuh-group}}"
export WAZUH_TAG="{{wazuh-tag}}"
export STACK_SVC="squid"
export SYSLOG_ROTATION="Enable"
export S3_BUCKET_NAME="${LOGS_BUCKET}"
export DATE="16-04-2026"
export REGION="${REGION}"
export SUDO_USER_LIST="{{sudo-user-list}}"
export NORMAL_USER_LIST="NA"
export SSH_SERVICE="PEM"
export VECTOR_S3_PATH="s3://${BUCKET_NAME}/${BUCKET_PATH_PREFIX}/vector.toml"
EOT
# ------------------------------ Initialization Script ------------------------------ #
echo "⏳ Copying initialization scripts..."
cp /home/01-init-script.sh /var/lib/cloud/scripts/per-instance/01-init-script.sh
chmod +x /var/lib/cloud/scripts/per-instance/01-init-script.sh
echo "✅ Mappings complete! Instance ready for Setup"

# Disable Squid task in sync-configs.py
SYNC_SCRIPT="/home/ubuntu/squid/scripts/sync-configs.py"
sed -i '/"Squid": configure_squid,/d' "$SYNC_SCRIPT"
sed -i '/"Squid": \["UFW"\],/d' "$SYNC_SCRIPT"
sed -i 's/"Squid", //' "$SYNC_SCRIPT"

# ------------------------------ Squid Configuration ------------------------------ #

echo "aws s3 cp s3://${BUCKET_NAME}/${BUCKET_PATH_PREFIX}/allowedlist.txt /etc/squid/tmp_whitelist.txt" > /etc/squid/update_whitelist.sh
echo "cp /etc/squid/squid.allowed.sites.txt /etc/squid/squid.allowed.sites.txt.old" >> /etc/squid/update_whitelist.sh
echo "cp /etc/squid/tmp_whitelist.txt /etc/squid/squid.allowed.sites.txt" >> /etc/squid/update_whitelist.sh
echo "/usr/sbin/squid -k reconfigure" >> /etc/squid/update_whitelist.sh
echo "`date "+%Y-%m-%d %H-%M-%S %Z"` Squid config updated"

chmod +x /etc/squid/update_whitelist.sh
sh /etc/squid/update_whitelist.sh
echo "*/15 * * * * root /etc/squid/update_whitelist.sh" >> /etc/crontab

aws s3 cp s3://${BUCKET_NAME}/${BUCKET_PATH_PREFIX}/squid.conf /etc/squid/squid.conf

systemctl restart squid.service

ufw allow out 19585

ufw allow out 80

aws s3 cp s3://${BUCKET_NAME}/${BUCKET_PATH_PREFIX}/vector.toml /home/ubuntu
cp /home/ubuntu/vector.toml /etc/vector/vector.toml
chmod +r /etc/vector/vector.toml
cp /lib/systemd/system/vector.service /lib/systemd/system/vector.service.bak
sed -i '/^User=vector/d' /lib/systemd/system/vector.service
sed -i '/^Group=vector/d' /lib/systemd/system/vector.service
sed -i 's|ExecStartPre=/usr/bin/vector validate|ExecStartPre=/usr/bin/vector validate /etc/vector/vector.toml|' /lib/systemd/system/vector.service
sed -i 's|ExecStart=/usr/bin/vector|ExecStart=/usr/bin/vector -c /etc/vector/vector.toml|' /lib/systemd/system/vector.service
sed -i 's|ExecReload=/usr/bin/vector validate /etc/vector.toml|ExecReload=/usr/bin/vector validate /etc/vector/vector.toml|' /lib/systemd/system/vector.service
systemctl daemon-reload
systemctl restart vector
systemctl enable vector

echo "Invalidation 6th march for instance refresh"