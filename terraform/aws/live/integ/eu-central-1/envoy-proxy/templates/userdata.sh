#!/bin/bash
set -e
set -x

sudo mkdir -p /home/ubuntu/
aws s3 cp s3://{{bucket-name}}/envoy/envoy.yaml /home/ubuntu/
sudo sed -i 's/^|//g' /home/ubuntu/envoy.yaml
sudo rm -rf /etc/envoy/envoy.yaml
sudo rm /dev/shm/envoy_shared_memory_*

# Create log directory and set proper permissions
sudo mkdir -p /var/log/envoy
sudo touch /var/log/envoy/listener-https_access.log
sudo chown -R envoy:envoy /var/log/envoy
sudo chmod 755 /var/log/envoy
sudo chmod 644 /var/log/envoy/listener-https_access.log

# Copy and configure Envoy config files
sudo cp /home/ubuntu/envoy.yaml /etc/envoy/envoy-config-template.yaml
sudo cp /home/ubuntu/envoy.yaml /etc/envoy/
sudo chmod ug+rw /etc/envoy/envoy.yaml
sudo chown envoy:envoy /etc/envoy/envoy.yaml
sudo chmod ug+rw /etc/envoy/envoy-config-template.yaml
sudo chown envoy:envoy /etc/envoy/envoy-config-template.yaml

# Restart Envoy service
sudo systemctl restart envoy.service
sudo systemctl status envoy.service