#!/bin/bash
# GCP equivalent of ../../../../aws/live/sandbox/ap-south-1/envoy-proxy/
# templates/userdata.sh - pulls envoy.yaml/vector.toml from the config
# bucket and (re)starts envoy.service/vector.service. Runs as a GCE
# startup-script (metadata_startup_script) on every boot, not just the
# first - matching AWS's userdata.sh, which also reruns on every boot
# cloud-init fires.
#
# Unlike AWS's userdata.sh, no {{bucket-name}}-style Terraform-side
# placeholder substitution is needed here: GCE's instance metadata server
# is queryable directly at boot, so this script just reads the
# "config-bucket" key the composition module already sets
# (hyperswitch-suite/terraform/gcp/modules/composition/envoy-proxy/main.tf)
# instead of having its value baked in ahead of time.
set -e
set -x

MD_FLAVOR_HEADER="Metadata-Flavor: Google"
MD_BASE="http://metadata.google.internal/computeMetadata/v1/instance"

fetch_meta() {
  curl -sf -H "$MD_FLAVOR_HEADER" "$1" || echo ""
}

CONFIG_BUCKET=$(fetch_meta "${MD_BASE}/attributes/config-bucket")

if [ -z "$CONFIG_BUCKET" ]; then
  echo "startup-script: no config-bucket metadata set, leaving existing config in place"
  exit 0
fi

# ------------------------------ Envoy config ------------------------------ #
gsutil cp "gs://${CONFIG_BUCKET}/envoy.yaml" /etc/envoy/envoy.yaml
chown envoy:envoy /etc/envoy/envoy.yaml
chmod 640 /etc/envoy/envoy.yaml
systemctl restart envoy.service

echo "The config has been changed, please verify"

# ------------------------------ Vector config ------------------------------ #
# Optional, unlike Envoy's - a fleet can run without a live-layer vector.toml
# override and just use the image's own baked-in default.
if gsutil -q stat "gs://${CONFIG_BUCKET}/vector.toml"; then
  gsutil cp "gs://${CONFIG_BUCKET}/vector.toml" /etc/vector/vector.toml
  chown root:vector /etc/vector/vector.toml
  chmod 640 /etc/vector/vector.toml
fi

# ------------------------------ Instance metadata for Vector -------------- #
# GCE equivalents of the EC2/ASG/Launch-Template tags AWS's userdata.sh
# writes to /etc/default/metadata: METADATA_ASG_NAME comes from the
# "created-by" attribute (the owning MIG's URL, GCE's ASG-name stand-in),
# METADATA_LT_VERSION from the "instance-template" attribute (GCE's
# launch-template-version stand-in). vector.toml's get_env_var("METADATA_*")
# calls read these.
INSTANCE_ID=$(fetch_meta "${MD_BASE}/id")
INSTANCE_IP=$(fetch_meta "${MD_BASE}/network-interfaces/0/ip")
CREATED_BY=$(fetch_meta "${MD_BASE}/attributes/created-by")
INSTANCE_TEMPLATE=$(fetch_meta "${MD_BASE}/attributes/instance-template")
ASG_NAME="${CREATED_BY##*/}"
LT_VERSION="${INSTANCE_TEMPLATE##*/}"

cat > /etc/default/metadata <<EOF
METADATA_INSTANCE_ID=${INSTANCE_ID:-unknown}
METADATA_INSTANCE_IP=${INSTANCE_IP:-unknown}
METADATA_ASG_NAME=${ASG_NAME:-unknown}
METADATA_LT_VERSION=${LT_VERSION:-unknown}
EOF

# EnvironmentFile drop-in feeding /etc/default/metadata to vector.service -
# written here (not baked into the image) so it's environment-specific
# wiring, matching AWS's userdata.sh writing its own environment.conf drop-in
# rather than shipping it in the AMI. The image's own drop-in
# (vector.service.d/gcp-overrides.conf) only fixes the config *path*, which
# is a fixed fact about this Vector package build, not environment-specific.
mkdir -p /etc/systemd/system/vector.service.d
cat > /etc/systemd/system/vector.service.d/environment.conf <<EOF
[Service]
EnvironmentFile=-/etc/default/metadata
EOF

systemctl daemon-reload
systemctl restart vector.service
