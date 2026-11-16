#!/bin/bash
set -euo pipefail

# =============================================================================
# /etc/default/metadata - the OCI equivalent of what AWS's userdata.sh writes
# =============================================================================
# The AWS envoy fleet's userdata writes EC2/ASG/Launch-Template facts into
# /etc/default/metadata, and vector.toml reads them back with
# get_env_var("METADATA_*") to tag every log line and metric with the instance
# and fleet it came from. Without this file every metric is tagged
# ltversion="unknown" and every log line asg_name="unknown", which makes the
# whole fleet indistinguishable in Prometheus and Loki - the dashboards still
# render, they just cannot answer "which instance".
#
# WHERE THIS DIVERGES FROM THE GCP PORT, AND WHY.
# GCP moved this population OUT of the image and into a live-layer
# startup-script (terraform/gcp/packer/envoy-proxy/scripts/
# vector-gcp-overrides.conf's own comment records the move), because GCP's
# composition module exposes `custom_startup_script` and the GCP live root
# uses it.
#
# THE OCI MODULE HAS NO SUCH SEAM. terraform/oci/modules/composition/
# envoy-proxy exposes `custom_user_data`, but the catalog unit
# (hyperswitch-infra:terraform/catalog/units/oci/envoy-proxy/terragrunt.hcl)
# does not set it, and the module instead passes `config_bucket`,
# `config_namespace` and `envoy_region` through `metadata` - i.e. the OCI
# module's contract is that THE IMAGE reads metadata and acts on it. The
# squid-proxy module's locals.tf states this outright next to its own metadata
# block: "The image's boot script and its 15-minute refresh timer read these
# off the metadata service rather than having the bucket baked in, which is
# what lets one image serve every environment."
#
# So on OCI this logic belongs in the image, and that is a deliberate,
# module-driven divergence from the GCP baseline rather than an oversight.
# If a `custom_user_data`-based live layer ever appears, this is the first
# thing that should move out to it.
#
# Nothing here needs credentials: IMDS is reachable from the instance itself
# with no identity at all, which is exactly why the metadata split works while
# the Object Storage fetch does not yet.
# =============================================================================

IMDS="http://169.254.169.254/opc/v2"
HDR="Authorization: Bearer Oracle"

get() { curl -sf -H "${HDR}" "${IMDS}/$1" 2>/dev/null | tr -d '"' || true; }

INSTANCE_ID=$(get instance/id)
INSTANCE_IP=$(get vnics/0/privateIp)
DISPLAY_NAME=$(get instance/displayName)

# The pool an instance belongs to is not a first-class IMDS field the way AWS's
# aws:autoscaling:groupName tag is. Two sources, in order of reliability:
#   1. `instance/definedTags` carries Oracle-Tags but not pool membership.
#   2. The instance pool sets the instance's display name from the instance
#      configuration's `display_name`, which the composition modules build as
#      "<env>-<project>-envoy-<deployment>". That is the closest honest
#      equivalent, and it is what the pool actually stamps on its members.
# Recorded rather than silently approximated: METADATA_ASG_NAME on OCI is a
# display-name prefix, not a pool OCID.
POOL_NAME="${DISPLAY_NAME:-unknown}"

# The instance configuration OCID is the launch-template-version analogue and
# IS exposed, under the freeform/defined tag set the module writes. Fall back
# to the image OCID, which at least changes when the fleet is re-imaged.
LT_VERSION=$(get instance/image)

umask 022
cat >/etc/default/metadata <<EOF
METADATA_INSTANCE_ID=${INSTANCE_ID:-unknown}
METADATA_INSTANCE_IP=${INSTANCE_IP:-unknown}
METADATA_ASG_NAME=${POOL_NAME}
METADATA_LT_VERSION=${LT_VERSION:-unknown}
EOF

echo "populate-oci-metadata: wrote /etc/default/metadata for ${INSTANCE_ID:-unknown}"
