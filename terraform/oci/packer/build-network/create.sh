#!/usr/bin/env bash
# =============================================================================
# Throwaway build network for the OCI Packer image builds
# =============================================================================
# WHY THIS EXISTS AT ALL, AND WHY IT IS NOT THE LIVE VCN.
#
# Packer's oracle-oci builder launches a temporary instance and provisions it
# over SSH from wherever `packer build` is running - a laptop or a CI runner,
# i.e. outside the VCN. That instance therefore needs an inbound SSH path.
# There are exactly three ways to give it one on OCI, and two were rejected:
#
#   1. REJECTED - build in the live `vpc-network` VCN with a public IP.
#      Read the applied dev VCN: twelve of its thirteen subnets carry
#      `prohibit_public_ip_on_vnic = true`, so a public IP on a build instance
#      is impossible in all of them. The single exception is
#      `external-incoming`, which is the load balancer's tier. Putting a
#      general-purpose build VM there, and opening SSH 22 into it, means
#      mutating the security posture of the one tier that faces the internet,
#      on a VCN that Terraform owns and whose default security list
#      `security-rules` asserts is empty. That is a drift risk on applied
#      infrastructure taken purely for a build-time convenience.
#
#   2. REJECTED (for now) - build privately and reach the instance through an
#      OCI Bastion session. `packer-plugin-oracle`'s own builder has no
#      bastion-specific argument (verified by reading builder/oci/config.go on
#      the plugin's main branch: the auth/network surface is
#      access_cfg_file / access_cfg_file_account / subnet_ocid /
#      create_vnic_details / use_private_ip, with no bastion field), so this
#      would have to run through Packer's GENERIC communicator settings
#      (ssh_bastion_host / ssh_bastion_username / ssh_bastion_private_key_file)
#      pointed at a managed OCI Bastion port-forwarding session. That is
#      plausible - an OCI Bastion session really is reached by SSH with the
#      session OCID as the username - but it needs a Bastion service instance
#      to exist first. None does: `bastion-host` is not in wave 1 and has never
#      been applied. Creating one by hand to serve a build would be creating
#      persistent infrastructure outside Terraform.
#
#   3. TAKEN - a self-contained, disposable VCN that exists only for the
#      duration of a build. Costs nothing (VCNs, subnets, gateways, route
#      tables and security lists are all free on OCI; only the build instance
#      bills, and Packer terminates it itself). Touches no applied resource.
#      Most importantly it keeps the image pipeline INDEPENDENT OF THE LIVE
#      STACK, which is the ordering `docs/multi-cloud-parity/oci/vm-tier-and-
#      images.md` section 2 explicitly asks for: "land the Packer template and
#      a real built image in the same change as (or before) the catalog unit
#      that consumes it". An image build that requires the production VCN to
#      already exist inverts that dependency.
#
# The build instance gets a public IP. That is a build-time property of a
# machine that lives for ten minutes in a network with nothing else in it -
# NOT a property of the image, and not a property of the fleet the image is
# later launched into (both proxy tiers set assign_public_ip = false on their
# instance configurations, in subnets that prohibit public IPs outright).
# The GCP port accepted the identical trade for its own Squid build, for a
# different reason (hashicorp/packer#12169 broke IAP tunnelling); see
# terraform/gcp/packer/squid-proxy/README.md.
#
# Usage:
#   ./create.sh                 # prints shell-eval-able OCIDs and writes .env
#   OCI_CLI_PROFILE=devuser ./create.sh
#
# Tear down with ./destroy.sh when the builds are finished. Nothing here is
# meant to outlive a build session.
# =============================================================================

set -euo pipefail

: "${OCI_CLI_PROFILE:=devuser}"
: "${OCI_CLI_AUTH:=security_token}"
export OCI_CLI_PROFILE OCI_CLI_AUTH

COMPARTMENT_ID="${COMPARTMENT_ID:?set COMPARTMENT_ID to the target compartment OCID}"
VCN_CIDR="${VCN_CIDR:-10.99.0.0/16}"
SUBNET_CIDR="${SUBNET_CIDR:-10.99.0.0/24}"
NAME_PREFIX="${NAME_PREFIX:-packer-build-temp}"
ENV_FILE="${ENV_FILE:-./build-network.env}"

# The SSH ingress rule is scoped to the caller's own egress address, not
# 0.0.0.0/0. A world-open port 22, even for ten minutes, is a different thing
# from a single-source one and there is no reason to accept it.
SSH_SOURCE_CIDR="${SSH_SOURCE_CIDR:-$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')/32}"

echo "compartment : ${COMPARTMENT_ID}"
echo "ssh source  : ${SSH_SOURCE_CIDR}"

VCN_ID=$(oci network vcn create \
  --compartment-id "${COMPARTMENT_ID}" \
  --cidr-blocks "[\"${VCN_CIDR}\"]" \
  --display-name "${NAME_PREFIX}" \
  --dns-label pkrbuild \
  --wait-for-state AVAILABLE --query 'data.id' --raw-output)
echo "vcn         : ${VCN_ID}"

IGW_ID=$(oci network internet-gateway create \
  --compartment-id "${COMPARTMENT_ID}" --vcn-id "${VCN_ID}" \
  --is-enabled true --display-name "${NAME_PREFIX}-igw" \
  --wait-for-state AVAILABLE --query 'data.id' --raw-output)
echo "igw         : ${IGW_ID}"

RT_ID=$(oci network route-table create \
  --compartment-id "${COMPARTMENT_ID}" --vcn-id "${VCN_ID}" \
  --display-name "${NAME_PREFIX}-rt" \
  --route-rules "[{\"destination\":\"0.0.0.0/0\",\"destinationType\":\"CIDR_BLOCK\",\"networkEntityId\":\"${IGW_ID}\"}]" \
  --wait-for-state AVAILABLE --query 'data.id' --raw-output)
echo "route table : ${RT_ID}"

SL_ID=$(oci network security-list create \
  --compartment-id "${COMPARTMENT_ID}" --vcn-id "${VCN_ID}" \
  --display-name "${NAME_PREFIX}-sl" \
  --egress-security-rules '[{"destination":"0.0.0.0/0","destinationType":"CIDR_BLOCK","protocol":"all","isStateless":false}]' \
  --ingress-security-rules "[{\"source\":\"${SSH_SOURCE_CIDR}\",\"sourceType\":\"CIDR_BLOCK\",\"protocol\":\"6\",\"isStateless\":false,\"tcpOptions\":{\"destinationPortRange\":{\"min\":22,\"max\":22}}}]" \
  --wait-for-state AVAILABLE --query 'data.id' --raw-output)
echo "sec list    : ${SL_ID}"

SUBNET_ID=$(oci network subnet create \
  --compartment-id "${COMPARTMENT_ID}" --vcn-id "${VCN_ID}" \
  --cidr-block "${SUBNET_CIDR}" \
  --display-name "${NAME_PREFIX}-public" --dns-label pkrpub \
  --route-table-id "${RT_ID}" --security-list-ids "[\"${SL_ID}\"]" \
  --prohibit-public-ip-on-vnic false \
  --wait-for-state AVAILABLE --query 'data.id' --raw-output)
echo "subnet      : ${SUBNET_ID}"

cat >"${ENV_FILE}" <<EOF
# Written by build-network/create.sh - consumed by destroy.sh.
COMPARTMENT_ID=${COMPARTMENT_ID}
VCN_ID=${VCN_ID}
IGW_ID=${IGW_ID}
RT_ID=${RT_ID}
SL_ID=${SL_ID}
SUBNET_ID=${SUBNET_ID}
EOF

echo
echo "Pass this to the Packer templates as subnet_ocid:"
echo "  ${SUBNET_ID}"
