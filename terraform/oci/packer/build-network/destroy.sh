#!/usr/bin/env bash
# =============================================================================
# Tear down the throwaway Packer build network created by create.sh
# =============================================================================
# Order matters and is not arbitrary: OCI refuses to delete a VCN while any
# subnet, gateway, route table or non-default security list still references
# it, and refuses to delete a subnet while a VNIC still lives in it. Packer
# terminates its own build instance, but a FAILED build can leave one behind
# (`packer build -on-error=abort`, or a hard kill), so this script checks for
# stragglers first and refuses rather than half-deleting the network.
#
# Usage:
#   ./destroy.sh                      # reads ./build-network.env
#   ENV_FILE=/path/to/build-network.env ./destroy.sh
# =============================================================================

set -euo pipefail

: "${OCI_CLI_PROFILE:=devuser}"
: "${OCI_CLI_AUTH:=security_token}"
export OCI_CLI_PROFILE OCI_CLI_AUTH

ENV_FILE="${ENV_FILE:-./build-network.env}"
[ -f "${ENV_FILE}" ] || { echo "no ${ENV_FILE}; nothing to do" >&2; exit 1; }
# shellcheck disable=SC1090
. "${ENV_FILE}"

LIVE=$(oci compute instance list --compartment-id "${COMPARTMENT_ID}" \
  --query 'data[?"lifecycle-state"!=`TERMINATED`].id' --raw-output 2>/dev/null || echo '[]')
for id in $(printf '%s' "${LIVE}" | tr -d '[]" ' | tr ',' '\n'); do
  [ -n "${id}" ] || continue
  VNIC_SUBNETS=$(oci compute instance list-vnics --instance-id "${id}" \
    --query 'data[].{"s":"subnet-id"}' --raw-output 2>/dev/null || true)
  case "${VNIC_SUBNETS}" in
    *"${SUBNET_ID}"*)
      echo "instance ${id} is still attached to ${SUBNET_ID}; terminate it first" >&2
      exit 1
      ;;
  esac
done

echo "deleting subnet       ${SUBNET_ID}"
oci network subnet delete --subnet-id "${SUBNET_ID}" --force --wait-for-state TERMINATED >/dev/null

echo "deleting security list ${SL_ID}"
oci network security-list delete --security-list-id "${SL_ID}" --force --wait-for-state TERMINATED >/dev/null

echo "deleting route table   ${RT_ID}"
oci network route-table delete --rt-id "${RT_ID}" --force --wait-for-state TERMINATED >/dev/null

echo "deleting igw           ${IGW_ID}"
oci network internet-gateway delete --ig-id "${IGW_ID}" --force --wait-for-state TERMINATED >/dev/null

echo "deleting vcn           ${VCN_ID}"
oci network vcn delete --vcn-id "${VCN_ID}" --force --wait-for-state TERMINATED >/dev/null

rm -f "${ENV_FILE}"
echo "build network gone"
